// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title WorkflowPFV - Planfeststellungsverfahren Smart Contract
 * @notice Vollstaendiger Workflow fuer Eisenbahn-Planfeststellungsverfahren
 * @dev Implementiert alle Phasen von Einreichung bis Beschluss inkl. NFT fuer Beschluss
 * 
 * Begleitcode zum ETR-Artikel "Blockchain in der Planfeststellung"
 * Datum: Januar 2026
 */
contract WorkflowPFV is ERC721, AccessControl {
    
    // ==================== ENUMS ====================
    
    enum Status {
        NichtEingereicht,           // Initial
        InPruefung,                 // VT hat eingereicht, 14-Tage-Frist laeuft
        NachbesserungErforderlich,  // Unvollstaendig, VT muss nachbessern
        Vollstaendig,               // Vollstaendigkeitspruefung bestanden
        InAnhoerung,                // TÖB + Auslegung laufen parallel
        AnhoerungAbgeschlossen,     // Beide Fristen abgelaufen
        PlanaenderungEingereicht,   // VT hat Planaenderung eingereicht
        EroerterungGeplant,         // Team hat entschieden: Eroerterung JA
        InEroeterterung,            // Eroerterungstermin laeuft
        EroeterterungAbgeschlossen, // Eroerterung beendet
        KeineEroeterterung,         // Team hat entschieden: Eroerterung NEIN
        InAbwaegung,                // Finale Abwaegung
        BeschlussErteilt,           // Beschluss erteilt, NFT vergeben
        Abgelehnt                   // Frist ueberschritten oder abgelehnt
    }
    
    enum Planaenderungstyp {
        Unwesentlich,      // Paragraph 76 Abs. 3 VwVfG - keine neue Anhoerung
        Wesentlich,        // Paragraph 76 Abs. 2 VwVfG - Auslegung fuer neue Betroffene
        Identitaetswechsel // Paragraph 77 VwVfG - komplett neues Verfahren
    }
    
    // ==================== ROLES ====================
    
    bytes32 public constant VORHABENTRAEGER_ROLE = keccak256("VORHABENTRAEGER_ROLE");
    bytes32 public constant SACHBEREICH_ROLE = keccak256("SACHBEREICH_ROLE");
    bytes32 public constant KANZLEI_ROLE = keccak256("KANZLEI_ROLE");
    bytes32 public constant TOEB_ROLE = keccak256("TOEB_ROLE");
    bytes32 public constant BEARBEITUNGSTEAM_ROLE = keccak256("BEARBEITUNGSTEAM_ROLE");
    bytes32 public constant EBA_ADMIN_ROLE = keccak256("EBA_ADMIN_ROLE");
    
    // ==================== STRUCTS ====================
    
    struct Dossier {
        bytes32 id;
        address vorhabentraeger;
        Status status;
        
        // Phase 1: Vollstaendigkeit
        bytes32[] dokumentHashes;
        uint256[] einreichungsZeitstempel;
        uint8 nachbesserungsRunden;
        uint256 pruefFrist;              // Behoerde hat 14 Tage
        uint256 nachbesserungsFrist;     // VT-Frist
        
        // Phase 2: Anhoerung
        uint256 toebFrist;
        uint256 auslegungsFrist;
        bytes32[] toebStellungnahmen;
        uint256[] toebZeitstempel;
        Einwendung[] einwendungen;
        
        // Phase 3: Planaenderungen
        Planaenderung[] planaenderungen;
        
        // Phase 4: Eroerterung
        bool eroerterungErforderlich;
        uint256 eroeterterungDatum;
        Einwendung[] nachtraeglicheEinwendungen;
        bytes32[] nachtraeglicheStellungnahmen;
        
        // Phase 5: Beschluss
        bytes32 beschlussHash;
        uint256 beschlussDatum;
        uint256 beschlussTokenId;
    }
    
    struct Einwendung {
        address einreicher;
        bytes32 hash;
        uint256 timestamp;
        bool nachtraeglich;
    }
    
    struct Planaenderung {
        bytes32 planHash;
        Planaenderungstyp typ;
        uint256 timestamp;
        address[] neueBetroffene;
        string begruendung;
        bool genehmigt;
    }
    
    // ==================== STATE VARIABLES ====================
    
    mapping(bytes32 => Dossier) public dossiers;
    mapping(address => bool) public berechtigteEinwender;
    
    uint256 private _nextTokenId;
    uint256 private _nextDossierId;
    
    // Konfiguration
    uint256 public constant PRUEF_FRIST_TAGE = 14;
    uint256 public constant STANDARD_NACHBESSERUNGS_FRIST_TAGE = 30;
    
    // ==================== EVENTS ====================
    
    event DossierEingereicht(
        bytes32 indexed dossierID,
        address indexed vorhabentraeger,
        bytes32 dokumentHash,
        uint256 timestamp
    );
    
    event VollstaendigkeitGeprueft(
        bytes32 indexed dossierID,
        bool vollstaendig,
        uint256 timestamp
    );
    
    event NachbesserungAngefordert(
        bytes32 indexed dossierID,
        uint256 frist,
        uint256 runde
    );
    
    event NachbesserungEingereicht(
        bytes32 indexed dossierID,
        bytes32 neuerHash,
        uint8 runde,
        uint256 timestamp
    );
    
    event AnhoerungGestartet(
        bytes32 indexed dossierID,
        uint256 toebFrist,
        uint256 auslegungsFrist
    );
    
    event TOEBStellungnahmeEingereicht(
        bytes32 indexed dossierID,
        address indexed toeb,
        bytes32 stellungnahmeHash,
        uint256 timestamp
    );
    
    event EinwendungEingereicht(
        bytes32 indexed dossierID,
        address indexed einreicher,
        bytes32 einwendungHash,
        uint256 timestamp,
        bool nachtraeglich
    );
    
    event EinwenderRegistriert(
        address indexed einwender,
        bytes32 indexed dossierID
    );
    
    event PlanaenderungEingereicht(
        bytes32 indexed dossierID,
        bytes32 neuerPlanHash,
        Planaenderungstyp typ,
        uint256 timestamp
    );
    
    event PlanaenderungGeprueft(
        bytes32 indexed dossierID,
        bool genehmigt,
        Planaenderungstyp typ
    );
    
    event EroeterterungEntschieden(
        bytes32 indexed dossierID,
        bool erforderlich,
        uint256 timestamp
    );
    
    event EroeterterungGestartet(
        bytes32 indexed dossierID,
        uint256 datum
    );
    
    event DossierAbgelehnt(
        bytes32 indexed dossierID,
        string grund,
        uint256 timestamp
    );
    
    event BeschlussErteilt(
        bytes32 indexed dossierID,
        bytes32 beschlussHash,
        uint256 tokenId,
        uint256 timestamp
    );
    
    // ==================== CONSTRUCTOR ====================
    
    constructor() ERC721("Planfeststellungsbeschluss", "PFB") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(EBA_ADMIN_ROLE, msg.sender);
    }
    
    // ==================== MODIFIERS ====================
    
    modifier dossierExists(bytes32 dossierID) {
        require(dossiers[dossierID].id != bytes32(0), "Dossier existiert nicht");
        _;
    }
    
    modifier inStatus(bytes32 dossierID, Status requiredStatus) {
        require(
            dossiers[dossierID].status == requiredStatus,
            "Falscher Status"
        );
        _;
    }
    
    // ==================== PHASE 1: EINREICHUNG & VOLLSTÄNDIGKEIT ====================
    
    /**
     * @notice VT reicht neues Dossier ein
     * @param dokumentHash Hash des Antragspakets
     * @return dossierID Eindeutige ID des Dossiers
     */
    function dossierEinreichen(bytes32 dokumentHash)
        external
        onlyRole(VORHABENTRAEGER_ROLE)
        returns (bytes32)
    {
        require(dokumentHash != bytes32(0), "Hash darf nicht leer sein");
        
        bytes32 dossierID = keccak256(
            abi.encodePacked(msg.sender, block.timestamp, _nextDossierId++)
        );
        
        Dossier storage d = dossiers[dossierID];
        d.id = dossierID;
        d.vorhabentraeger = msg.sender;
        d.status = Status.InPruefung;
        d.dokumentHashes.push(dokumentHash);
        d.einreichungsZeitstempel.push(block.timestamp);
        d.pruefFrist = block.timestamp + (PRUEF_FRIST_TAGE * 1 days);
        d.nachbesserungsRunden = 0;
        
        emit DossierEingereicht(dossierID, msg.sender, dokumentHash, block.timestamp);
        
        return dossierID;
    }
    
    /**
     * @notice Sachbereich prueft Vollstaendigkeit
     * @param dossierID ID des Dossiers
     * @param vollstaendig Ist das Dossier vollstaendig?
     */
    function pruefeVollstaendigkeit(bytes32 dossierID, bool vollstaendig)
        external
        onlyRole(SACHBEREICH_ROLE)
        dossierExists(dossierID)
        inStatus(dossierID, Status.InPruefung)
    {
        Dossier storage d = dossiers[dossierID];
        require(block.timestamp <= d.pruefFrist, "Prueffrist abgelaufen");
        
        if (vollstaendig) {
            d.status = Status.Vollstaendig;
        } else {
            d.status = Status.NachbesserungErforderlich;
            d.nachbesserungsFrist = block.timestamp + 
                (STANDARD_NACHBESSERUNGS_FRIST_TAGE * 1 days);
            d.nachbesserungsRunden++;
            
            emit NachbesserungAngefordert(
                dossierID,
                d.nachbesserungsFrist,
                d.nachbesserungsRunden
            );
        }
        
        emit VollstaendigkeitGeprueft(dossierID, vollstaendig, block.timestamp);
    }
    
    /**
     * @notice VT reicht Nachbesserung ein
     * @param dossierID ID des Dossiers
     * @param neuerDokumentHash Hash der nachgebesserten Unterlagen
     */
    function nachbesserungEinreichen(bytes32 dossierID, bytes32 neuerDokumentHash)
        external
        onlyRole(VORHABENTRAEGER_ROLE)
        dossierExists(dossierID)
        inStatus(dossierID, Status.NachbesserungErforderlich)
    {
        Dossier storage d = dossiers[dossierID];
        require(msg.sender == d.vorhabentraeger, "Nicht Ihr Dossier");
        require(block.timestamp <= d.nachbesserungsFrist, "Nachbesserungsfrist abgelaufen");
        require(neuerDokumentHash != bytes32(0), "Hash darf nicht leer sein");
        
        d.dokumentHashes.push(neuerDokumentHash);
        d.einreichungsZeitstempel.push(block.timestamp);
        d.status = Status.InPruefung;
        d.pruefFrist = block.timestamp + (PRUEF_FRIST_TAGE * 1 days);
        
        emit NachbesserungEingereicht(
            dossierID,
            neuerDokumentHash,
            d.nachbesserungsRunden,
            block.timestamp
        );
    }
    
    /**
     * @notice Prueft ob VT-Frist abgelaufen ist und lehnt ggf. ab
     * @param dossierID ID des Dossiers
     */
    function pruefeFrist(bytes32 dossierID)
        external
        dossierExists(dossierID)
    {
        Dossier storage d = dossiers[dossierID];
        
        if (d.status == Status.NachbesserungErforderlich &&
            block.timestamp > d.nachbesserungsFrist) {
            
            d.status = Status.Abgelehnt;
            emit DossierAbgelehnt(
                dossierID,
                "Nachbesserungsfrist ueberschritten",
                block.timestamp
            );
        }
    }
    
    // ==================== PHASE 2: ANHÖRUNG ====================
    
    /**
     * @notice Kanzlei startet Anhoerungsphase (TÖB + Auslegung parallel)
     * @param dossierID ID des Dossiers
     * @param toebFristTage Frist fuer TÖB in Tagen
     * @param auslegungFristTage Frist fuer oeffentliche Auslegung in Tagen
     */
    function starteAnhoerung(
        bytes32 dossierID,
        uint256 toebFristTage,
        uint256 auslegungFristTage
    )
        external
        onlyRole(KANZLEI_ROLE)
        dossierExists(dossierID)
        inStatus(dossierID, Status.Vollstaendig)
    {
        require(toebFristTage > 0 && auslegungFristTage > 0, "Fristen muessen > 0 sein");
        
        Dossier storage d = dossiers[dossierID];
        d.status = Status.InAnhoerung;
        d.toebFrist = block.timestamp + (toebFristTage * 1 days);
        d.auslegungsFrist = block.timestamp + (auslegungFristTage * 1 days);
        
        emit AnhoerungGestartet(dossierID, d.toebFrist, d.auslegungsFrist);
    }
    
    /**
     * @notice TÖB reicht Stellungnahme ein
     * @param dossierID ID des Dossiers
     * @param stellungnahmeHash Hash der Stellungnahme
     */
    function toebStellungnahmeEinreichen(
        bytes32 dossierID,
        bytes32 stellungnahmeHash
    )
        external
        onlyRole(TOEB_ROLE)
        dossierExists(dossierID)
    {
        Dossier storage d = dossiers[dossierID];
        require(
            d.status == Status.InAnhoerung || d.status == Status.InEroeterterung,
            "Nicht in Anhoerung/Eroerterung"
        );
        require(block.timestamp <= d.toebFrist, "TOEB-Frist abgelaufen");
        require(stellungnahmeHash != bytes32(0), "Hash darf nicht leer sein");
        
        d.toebStellungnahmen.push(stellungnahmeHash);
        d.toebZeitstempel.push(block.timestamp);
        
        emit TOEBStellungnahmeEingereicht(
            dossierID,
            msg.sender,
            stellungnahmeHash,
            block.timestamp
        );
    }
    
    /**
     * @notice Kanzlei registriert berechtigten Einwender (nach off-chain Pruefung)
     * @param einwender Adresse des Einwenders
     * @param dossierID ID des Dossiers
     */
    function registriereEinwender(address einwender, bytes32 dossierID)
        external
        onlyRole(KANZLEI_ROLE)
        dossierExists(dossierID)
    {
        berechtigteEinwender[einwender] = true;
        emit EinwenderRegistriert(einwender, dossierID);
    }
    
    /**
     * @notice Buerger reicht Einwendung ein (nur wenn berechtigt)
     * @param dossierID ID des Dossiers
     * @param einwendungHash Hash der Einwendung
     */
    function einwendungEinreichen(bytes32 dossierID, bytes32 einwendungHash)
        external
        dossierExists(dossierID)
    {
        require(berechtigteEinwender[msg.sender], "Nicht berechtigt");
        Dossier storage d = dossiers[dossierID];
        require(
            d.status == Status.InAnhoerung || d.status == Status.InEroeterterung,
            "Nicht in Anhoerung/Eroerterung"
        );
        require(einwendungHash != bytes32(0), "Hash darf nicht leer sein");
        
        bool istNachtraeglich = (d.status == Status.InEroeterterung);
        
        if (istNachtraeglich) {
            d.nachtraeglicheEinwendungen.push(Einwendung({
                einreicher: msg.sender,
                hash: einwendungHash,
                timestamp: block.timestamp,
                nachtraeglich: true
            }));
        } else {
            require(block.timestamp <= d.auslegungsFrist, "Auslegungsfrist abgelaufen");
            d.einwendungen.push(Einwendung({
                einreicher: msg.sender,
                hash: einwendungHash,
                timestamp: block.timestamp,
                nachtraeglich: false
            }));
        }
        
        emit EinwendungEingereicht(
            dossierID,
            msg.sender,
            einwendungHash,
            block.timestamp,
            istNachtraeglich
        );
    }
    
    /**
     * @notice Kanzlei schliesst Anhoerung ab (nach Ablauf beider Fristen)
     * @param dossierID ID des Dossiers
     */
    function schliesseAnhoerung(bytes32 dossierID)
        external
        onlyRole(KANZLEI_ROLE)
        dossierExists(dossierID)
        inStatus(dossierID, Status.InAnhoerung)
    {
        Dossier storage d = dossiers[dossierID];
        require(
            block.timestamp > d.toebFrist && block.timestamp > d.auslegungsFrist,
            "Fristen noch nicht abgelaufen"
        );
        
        d.status = Status.AnhoerungAbgeschlossen;
    }
    
    // ==================== PHASE 3: PLANÄNDERUNGEN ====================
    
    /**
     * @notice VT reicht Planaenderung ein (waehrend Anhoerung)
     * @param dossierID ID des Dossiers
     * @param neuerPlanHash Hash der geaenderten Plaene
     * @param begruendung Begruendung der Änderung
     */
    function planaenderungEinreichen(
        bytes32 dossierID,
        bytes32 neuerPlanHash,
        string calldata begruendung
    )
        external
        onlyRole(VORHABENTRAEGER_ROLE)
        dossierExists(dossierID)
    {
        Dossier storage d = dossiers[dossierID];
        require(msg.sender == d.vorhabentraeger, "Nicht Ihr Dossier");
        require(
            d.status == Status.InAnhoerung || d.status == Status.InEroeterterung,
            "Nur waehrend Anhoerung/Eroerterung"
        );
        require(neuerPlanHash != bytes32(0), "Hash darf nicht leer sein");
        
        d.status = Status.PlanaenderungEingereicht;
        
        d.planaenderungen.push(Planaenderung({
            planHash: neuerPlanHash,
            typ: Planaenderungstyp.Unwesentlich,
            timestamp: block.timestamp,
            neueBetroffene: new address[](0),
            begruendung: begruendung,
            genehmigt: false
        }));
        
        emit PlanaenderungEingereicht(
            dossierID,
            neuerPlanHash,
            Planaenderungstyp.Unwesentlich,
            block.timestamp
        );
    }
    
    /**
     * @notice Bearbeitungsteam klassifiziert und genehmigt Planaenderung
     * @param dossierID ID des Dossiers
     * @param aenderungIndex Index der Planaenderung
     * @param typ Typ der Änderung
     * @param neueBetroffene Adressen neu betroffener Personen
     */
    function planaenderungPruefen(
        bytes32 dossierID,
        uint256 aenderungIndex,
        Planaenderungstyp typ,
        address[] calldata neueBetroffene
    )
        external
        onlyRole(BEARBEITUNGSTEAM_ROLE)
        dossierExists(dossierID)
        inStatus(dossierID, Status.PlanaenderungEingereicht)
    {
        Dossier storage d = dossiers[dossierID];
        require(aenderungIndex < d.planaenderungen.length, "Ungueltiger Index");
        
        Planaenderung storage aenderung = d.planaenderungen[aenderungIndex];
        aenderung.typ = typ;
        aenderung.genehmigt = true;
        
        if (typ == Planaenderungstyp.Unwesentlich) {
            d.status = Status.InAnhoerung;
        } else if (typ == Planaenderungstyp.Wesentlich) {
            for (uint i = 0; i < neueBetroffene.length; i++) {
                aenderung.neueBetroffene.push(neueBetroffene[i]);
                berechtigteEinwender[neueBetroffene[i]] = true;
            }
            d.status = Status.InAnhoerung;
        } else {
            d.status = Status.Abgelehnt;
            emit DossierAbgelehnt(
                dossierID,
                "Identitaetswechsel - neues Verfahren nach Paragraph77 VwVfG erforderlich",
                block.timestamp
            );
        }
        
        emit PlanaenderungGeprueft(dossierID, true, typ);
    }
    
    // ==================== PHASE 4: ERÖRTERUNG ====================
    
    /**
     * @notice Bearbeitungsteam entscheidet ueber Eroerterungstermin
     * @param dossierID ID des Dossiers
     * @param erforderlich Ist Eroerterung erforderlich?
     */
    function entscheideEroeterterung(bytes32 dossierID, bool erforderlich)
        external
        onlyRole(BEARBEITUNGSTEAM_ROLE)
        dossierExists(dossierID)
        inStatus(dossierID, Status.AnhoerungAbgeschlossen)
    {
        Dossier storage d = dossiers[dossierID];
        d.eroerterungErforderlich = erforderlich;
        
        if (erforderlich) {
            d.status = Status.EroerterungGeplant;
        } else {
            d.status = Status.InAbwaegung;
        }
        
        emit EroeterterungEntschieden(dossierID, erforderlich, block.timestamp);
    }
    
    /**
     * @notice Kanzlei startet Eroerterungstermin
     * @param dossierID ID des Dossiers
     */
    function starteEroeterterung(bytes32 dossierID)
        external
        onlyRole(KANZLEI_ROLE)
        dossierExists(dossierID)
        inStatus(dossierID, Status.EroerterungGeplant)
    {
        Dossier storage d = dossiers[dossierID];
        d.status = Status.InEroeterterung;
        d.eroeterterungDatum = block.timestamp;
        
        emit EroeterterungGestartet(dossierID, block.timestamp);
    }
    
    /**
     * @notice Kanzlei schliesst Eroerterung ab
     * @param dossierID ID des Dossiers
     */
    function schliesseEroeterterung(bytes32 dossierID)
        external
        onlyRole(KANZLEI_ROLE)
        dossierExists(dossierID)
        inStatus(dossierID, Status.InEroeterterung)
    {
        Dossier storage d = dossiers[dossierID];
        d.status = Status.InAbwaegung;
    }
    
    // ==================== PHASE 5: BESCHLUSS ====================
    
    /**
     * @notice Sachbereich erteilt Planfeststellungsbeschluss und vergibt NFT
     * @param dossierID ID des Dossiers
     * @param beschlussHash Hash des Beschlussdokuments
     */
    function erteileBeschluss(bytes32 dossierID, bytes32 beschlussHash)
        external
        onlyRole(SACHBEREICH_ROLE)
        dossierExists(dossierID)
        inStatus(dossierID, Status.InAbwaegung)
    {
        require(beschlussHash != bytes32(0), "Hash darf nicht leer sein");
        
        Dossier storage d = dossiers[dossierID];
        
        uint256 tokenId = _nextTokenId++;
        _mint(d.vorhabentraeger, tokenId);
        
        d.status = Status.BeschlussErteilt;
        d.beschlussHash = beschlussHash;
        d.beschlussDatum = block.timestamp;
        d.beschlussTokenId = tokenId;
        
        emit BeschlussErteilt(dossierID, beschlussHash, tokenId, block.timestamp);
    }
    
    /**
     * @notice Verhindert Transfer von Beschluss-NFTs (Soulbound Token)
     */
    function _update(address to, uint256 tokenId, address auth)
        internal
        override
        returns (address)
    {
        address from = _ownerOf(tokenId);
        if (from != address(0)) {
            revert("Beschluss nicht uebertragbar - Soulbound Token");
        }
        return super._update(to, tokenId, auth);
    }
    
    // ==================== VIEW FUNCTIONS ====================
    
    /**
     * @notice Liefert vollstaendigen Dossier-Status
     */
    function getDossierStatus(bytes32 dossierID)
        external
        view
        dossierExists(dossierID)
        returns (
            Status status,
            address vorhabentraeger,
            uint8 nachbesserungsRunden,
            uint256 anzahlEinwendungen,
            uint256 anzahlTOEBStellungnahmen,
            uint256 anzahlPlanaenderungen,
            bool beschlussErteilt,
            uint256 beschlussTokenId
        )
    {
        Dossier storage d = dossiers[dossierID];
        return (
            d.status,
            d.vorhabentraeger,
            d.nachbesserungsRunden,
            d.einwendungen.length + d.nachtraeglicheEinwendungen.length,
            d.toebStellungnahmen.length,
            d.planaenderungen.length,
            d.status == Status.BeschlussErteilt,
            d.beschlussTokenId
        );
    }
    
    /**
     * @notice Liefert Dokument-History
     */
    function getDokumentHistory(bytes32 dossierID)
        external
        view
        dossierExists(dossierID)
        returns (bytes32[] memory hashes, uint256[] memory timestamps)
    {
        Dossier storage d = dossiers[dossierID];
        return (d.dokumentHashes, d.einreichungsZeitstempel);
    }
    
    /**
     * @notice Prueft ob Adresse berechtigter Einwender ist
     */
    function istBerechtigt(address einwender) external view returns (bool) {
        return berechtigteEinwender[einwender];
    }
    
    // ==================== ADMIN FUNCTIONS ====================
    
    function grantRoleToAddress(bytes32 role, address account)
        external
        onlyRole(EBA_ADMIN_ROLE)
    {
        _grantRole(role, account);
    }
    
    function revokeRoleFromAddress(bytes32 role, address account)
        external
        onlyRole(EBA_ADMIN_ROLE)
    {
        _revokeRole(role, account);
    }
    
    // ==================== REQUIRED OVERRIDES ====================
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
