// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title WorkflowPFV
 * @notice Smart Contract für Planfeststellungsverfahren im Eisenbahnwesen
 * @dev Implementiert eine State Machine für den Verfahrensablauf gemäß AEG und VwVfG
 * 
 * Dieses Contract bildet den Planfeststellungsprozess als Zustandsautomaten ab:
 * - Einreichung → Vollständigkeit → Auslegung → Abwägung → Beschlussentwurf → Beschluss → Rechtskraft
 * 
 * Hauptfunktionen:
 * - Hash-Registry für Dokumentversionen (Off-Chain-Daten werden über Merkle-Root verankert)
 * - Workflow-Gates (Phasenwechsel nur bei erfüllten Bedingungen)
 * - Event-Trail (Lückenlose Protokollierung aller Verfahrensschritte)
 * - Rollenbasierte Zugriffskontrolle (Sachbereich 1, Fachprüfer, TÖB, Vorhabenträger, Öffentlichkeit)
 */
contract WorkflowPFV {
    
    /*//////////////////////////////////////////////////////////////
                                 ENUMS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Verfahrensstatus nach Planfeststellungsrichtlinien
     * @dev Jeder Status repräsentiert eine Phase im Planfeststellungsverfahren
     */
    enum Status {
        Einreichung,        // Antrag wurde eingereicht
        Vollstaendigkeit,   // Vollständigkeitsprüfung läuft
        Auslegung,          // Öffentliche Auslegung und TÖB-Beteiligung
        Abwaegung,          // Abwägung der Einwendungen
        BeschlussEntwurf,   // Beschlussentwurf wird erstellt
        Beschluss,          // Planfeststellungsbeschluss erteilt
        Rechtskraft         // Beschluss ist rechtskräftig
    }
    
    /**
     * @notice Rollen im Verfahren
     * @dev Entspricht der Organisationsstruktur einer Planfeststellungsbehörde
     */
    enum Role {
        None,               // Keine Rolle (Default)
        Vorhabentraeger,    // Antragsteller (z.B. DB InfraGO)
        Toeb,               // Träger öffentlicher Belange
        Fach,               // Fachprüfer (Wasserbehörde, Naturschutz, etc.)
        Sachbereich1PF      // Sachbereich 1 Planfeststellung (Verfahrensleitung)
    }
    
    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Struktur für ein Planfeststellungsverfahren
     * @dev Enthält alle verfahrensrelevanten Informationen
     */
    struct Verfahren {
        bytes32 dossierId;              // Eindeutige Verfahrens-ID
        Status status;                  // Aktueller Verfahrensstatus
        address vorhabentraeger;        // Adresse des Vorhabenträgers
        bytes32 merkleRoot;             // Merkle-Root aller eingereichten Dokumente
        uint256 einreichungsDatum;      // Zeitstempel der Einreichung
        uint256 auslegungsfrist;        // Ende der Auslegungsfrist (Unix-Timestamp)
        bool vollstaendigkeitBestaetigt;// Vollständigkeitsprüfung abgeschlossen
        bool toebBeteiligt;             // TÖB-Beteiligung abgeschlossen
        uint256 anzahlEinwendungen;     // Anzahl der eingereichten Einwendungen
        uint256 offeneEinwendungen;     // Noch nicht abgewogene Einwendungen
    }
    
    /**
     * @notice Struktur für Einwendungen
     * @dev Verwaltet Einwendungen der Öffentlichkeit
     */
    struct Einwendung {
        bytes32 einwendungsId;          // Eindeutige ID der Einwendung
        bytes32 dossierId;              // Zugehöriges Verfahren
        address einwender;              // Adresse des Einwenders
        bytes32 dokumentHash;           // Hash der Einwendung (Off-Chain)
        uint256 eingangsDatum;          // Zeitstempel des Eingangs
        bool fristgerecht;              // Innerhalb der Frist eingereicht
        bool bearbeitet;                // Abwägung erfolgt
    }
    
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    
    // Verfahren
    mapping(bytes32 => Verfahren) public verfahren;
    bytes32[] public verfahrenListe;
    
    // Rollen
    mapping(address => Role) public rollen;
    
    // Einwendungen
    mapping(bytes32 => Einwendung) public einwendungen;
    mapping(bytes32 => bytes32[]) public verfahrenEinwendungen; // dossierId => einwendungsIds
    
    // Hash-Registry für Dokumente
    mapping(bytes32 => bytes32) public dokumentHashes; // dokumentId => hash
    
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Event bei Verfahrensfortschritt
     * @dev Wird bei jedem Statuswechsel emittiert (Audit Trail)
     */
    event Fortschritt(
        bytes32 indexed dossierId,
        Status von,
        Status nach,
        uint256 zeitstempel,
        address initiator
    );
    
    /**
     * @notice Event bei Dokumenten-Verankerung
     */
    event DokumentVerankert(
        bytes32 indexed dossierId,
        bytes32 indexed dokumentId,
        bytes32 hash,
        uint256 zeitstempel
    );
    
    /**
     * @notice Event bei Einwendungs-Eingang
     */
    event EinwendungEingereicht(
        bytes32 indexed dossierId,
        bytes32 indexed einwendungsId,
        address einwender,
        uint256 zeitstempel,
        bool fristgerecht
    );
    
    /**
     * @notice Event bei Rollenänderung
     */
    event RolleZugewiesen(
        address indexed account,
        Role rolle,
        uint256 zeitstempel
    );
    
    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Prüft ob Aufrufer die erforderliche Rolle hat
     */
    modifier nurRolle(Role _rolle) {
        require(rollen[msg.sender] == _rolle, "Unzureichende Berechtigung");
        _;
    }
    
    /**
     * @notice Prüft ob Verfahren existiert
     */
    modifier verfahrenExistiert(bytes32 _dossierId) {
        require(verfahren[_dossierId].dossierId != bytes32(0), "Verfahren existiert nicht");
        _;
    }
    
    /*//////////////////////////////////////////////////////////////
                         CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    
    constructor() {
        // Deployer erhält Sachbereich1PF-Rolle
        rollen[msg.sender] = Role.Sachbereich1PF;
        emit RolleZugewiesen(msg.sender, Role.Sachbereich1PF, block.timestamp);
    }
    
    /*//////////////////////////////////////////////////////////////
                        ROLLENVERWALTUNG
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Weist einem Account eine Rolle zu
     * @dev Nur Sachbereich1PF darf Rollen vergeben
     */
    function rolleZuweisen(address _account, Role _rolle) 
        external 
        nurRolle(Role.Sachbereich1PF) 
    {
        require(_account != address(0), "Ungueltige Adresse");
        rollen[_account] = _rolle;
        emit RolleZugewiesen(_account, _rolle, block.timestamp);
    }
    
    /*//////////////////////////////////////////////////////////////
                    VERFAHREN INITIIERUNG
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Neues Planfeststellungsverfahren einreichen
     * @dev Nur Vorhabenträger dürfen Verfahren einreichen
     * @param _dossierId Eindeutige Verfahrens-ID
     * @param _merkleRoot Merkle-Root aller Antragsunterlagen
     */
    function verfahrenEinreichen(bytes32 _dossierId, bytes32 _merkleRoot)
        external
        nurRolle(Role.Vorhabentraeger)
    {
        require(_dossierId != bytes32(0), "Ungueltige Dossier-ID");
        require(verfahren[_dossierId].dossierId == bytes32(0), "Verfahren existiert bereits");
        require(_merkleRoot != bytes32(0), "Merkle-Root erforderlich");
        
        Verfahren memory neuesVerfahren = Verfahren({
            dossierId: _dossierId,
            status: Status.Einreichung,
            vorhabentraeger: msg.sender,
            merkleRoot: _merkleRoot,
            einreichungsDatum: block.timestamp,
            auslegungsfrist: 0,
            vollstaendigkeitBestaetigt: false,
            toebBeteiligt: false,
            anzahlEinwendungen: 0,
            offeneEinwendungen: 0
        });
        
        verfahren[_dossierId] = neuesVerfahren;
        verfahrenListe.push(_dossierId);
        
        emit Fortschritt(
            _dossierId,
            Status.Einreichung,
            Status.Einreichung,
            block.timestamp,
            msg.sender
        );
    }
    
    /*//////////////////////////////////////////////////////////////
                    WORKFLOW GATES (TO BE IMPLEMENTED)
    //////////////////////////////////////////////////////////////*/
    
    // TODO: Implement phase transitions with gate logic
    // - vollstaendigkeitPruefen()
    // - auslegungStarten()
    // - einwendungEinreichen()
    // - abwaegungAbschliessen()
    // - beschlussErstellen()
    // - rechtskraftFeststellen()
    
    /*//////////////////////////////////////////////////////////////
                         VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Gibt Verfahrensinformationen zurück
     */
    function getVerfahren(bytes32 _dossierId) 
        external 
        view 
        verfahrenExistiert(_dossierId)
        returns (Verfahren memory) 
    {
        return verfahren[_dossierId];
    }
    
    /**
     * @notice Gibt Anzahl der Verfahren zurück
     */
    function getAnzahlVerfahren() external view returns (uint256) {
        return verfahrenListe.length;
    }
    
    /**
     * @notice Gibt Rolle eines Accounts zurück
     */
    function getRolle(address _account) external view returns (Role) {
        return rollen[_account];
    }
}
