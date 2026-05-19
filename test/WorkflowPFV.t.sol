// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../contracts/WorkflowPFV_v1_deployed.sol";

/**
 * @title WorkflowPFVTest
 * @notice Automatisierte Tests fuer den WorkflowPFV Smart Contract
 * @dev Deckt ab: Happy Path, Negative Tests (Fehlerfaelle), Edge Cases, Access Control
 *
 * Begleitcode zum ETR-Artikel "Blockchain in der Planfeststellung"
 */
contract WorkflowPFVTest is Test {

    WorkflowPFV public workflow;

    // Test Accounts
    address public admin;
    address public sachbereich;
    address public vorhabentraeger;
    address public kanzlei;
    address public toeb;
    address public bearbeitungsteam;
    address public buerger;
    address public unbefugter;

    // Test Daten
    bytes32 public testDokumentHash;
    bytes32 public testBeschlussHash;

    function setUp() public {
        admin           = address(this);
        sachbereich     = makeAddr("sachbereich");
        vorhabentraeger = makeAddr("vorhabentraeger");
        kanzlei         = makeAddr("kanzlei");
        toeb            = makeAddr("toeb");
        bearbeitungsteam = makeAddr("bearbeitungsteam");
        buerger         = makeAddr("buerger");
        unbefugter      = makeAddr("unbefugter");

        testDokumentHash = keccak256("PLANUNTERLAGEN_V1");
        testBeschlussHash = keccak256("PLANFESTSTELLUNGSBESCHLUSS_FINAL");

        // Contract deployen
        workflow = new WorkflowPFV();

        // Rollen zuweisen (admin = this contract nach constructor)
        workflow.grantRoleToAddress(workflow.SACHBEREICH_ROLE(), sachbereich);
        workflow.grantRoleToAddress(workflow.VORHABENTRAEGER_ROLE(), vorhabentraeger);
        workflow.grantRoleToAddress(workflow.KANZLEI_ROLE(), kanzlei);
        workflow.grantRoleToAddress(workflow.TOEB_ROLE(), toeb);
        workflow.grantRoleToAddress(workflow.BEARBEITUNGSTEAM_ROLE(), bearbeitungsteam);
    }

    // ==================== HILFSFUNKTION ====================

    /// @dev Fuehrt den vollstaendigen Happy Path bis zum angegebenen Status durch
    function _setupBisVollstaendig() internal returns (bytes32 dossierID) {
        vm.prank(vorhabentraeger);
        dossierID = workflow.dossierEinreichen(testDokumentHash);

        vm.prank(sachbereich);
        workflow.pruefeVollstaendigkeit(dossierID, true);
    }

    function _setupBisAnhoerung() internal returns (bytes32 dossierID) {
        dossierID = _setupBisVollstaendig();

        vm.prank(kanzlei);
        workflow.starteAnhoerung(dossierID, 30, 30);
    }

    function _setupBisAbwaegung() internal returns (bytes32 dossierID) {
        dossierID = _setupBisAnhoerung();

        // Fristen ablaufen lassen
        vm.warp(block.timestamp + 31 days);

        vm.prank(kanzlei);
        workflow.schliesseAnhoerung(dossierID);

        vm.prank(bearbeitungsteam);
        workflow.entscheideEroeterterung(dossierID, false);
    }

    // ==================== DEPLOYMENT TESTS ====================

    function test_Deployment_ContractExistiert() public view {
        assertTrue(address(workflow) != address(0));
    }

    function test_Deployment_AdminHatRolle() public view {
        assertTrue(workflow.hasRole(workflow.EBA_ADMIN_ROLE(), admin));
    }

    function test_Deployment_RollenKorrektZugewiesen() public view {
        assertTrue(workflow.hasRole(workflow.SACHBEREICH_ROLE(), sachbereich));
        assertTrue(workflow.hasRole(workflow.VORHABENTRAEGER_ROLE(), vorhabentraeger));
        assertTrue(workflow.hasRole(workflow.KANZLEI_ROLE(), kanzlei));
        assertTrue(workflow.hasRole(workflow.TOEB_ROLE(), toeb));
        assertTrue(workflow.hasRole(workflow.BEARBEITUNGSTEAM_ROLE(), bearbeitungsteam));
    }

    // ==================== HAPPY PATH: VOLLSTAENDIGER VERFAHRENSABLAUF ====================

    function test_HappyPath_DossierEinreichen() public {
        vm.prank(vorhabentraeger);
        bytes32 dossierID = workflow.dossierEinreichen(testDokumentHash);

        (
            WorkflowPFV.Status status,
            address vt,
            uint8 runden,
            ,,,,,
        ) = workflow.getDossierStatus(dossierID);

        assertEq(uint(status), uint(WorkflowPFV.Status.InPruefung));
        assertEq(vt, vorhabentraeger);
        assertEq(runden, 0);
    }

    function test_HappyPath_VollstaendigkeitBestaetigen() public {
        bytes32 dossierID = _setupBisVollstaendig();

        (WorkflowPFV.Status status,,,,,,, ) = workflow.getDossierStatus(dossierID);
        assertEq(uint(status), uint(WorkflowPFV.Status.Vollstaendig));
    }

    function test_HappyPath_AnhoerungStarten() public {
        bytes32 dossierID = _setupBisAnhoerung();

        (WorkflowPFV.Status status,,,,,,, ) = workflow.getDossierStatus(dossierID);
        assertEq(uint(status), uint(WorkflowPFV.Status.InAnhoerung));
    }

    function test_HappyPath_EinwendungFristgerecht() public {
        bytes32 dossierID = _setupBisAnhoerung();

        // Buerger als Einwender registrieren
        vm.prank(kanzlei);
        workflow.registriereEinwender(buerger, dossierID);

        // Einwendung innerhalb der Frist einreichen
        bytes32 einwendungHash = keccak256("EINWENDUNG_LAERM");
        vm.prank(buerger);
        workflow.einwendungEinreichen(dossierID, einwendungHash);

        (,,, uint256 anzahlEinwendungen,,,, ) = workflow.getDossierStatus(dossierID);
        assertEq(anzahlEinwendungen, 1);
    }

    function test_HappyPath_ToebStellungnahme() public {
        bytes32 dossierID = _setupBisAnhoerung();

        bytes32 stellungnahmeHash = keccak256("TOEB_STELLUNGNAHME_NATURSCHUTZ");
        vm.prank(toeb);
        workflow.toebStellungnahmeEinreichen(dossierID, stellungnahmeHash);

        (,,,, uint256 anzahlToeb,,, ) = workflow.getDossierStatus(dossierID);
        assertEq(anzahlToeb, 1);
    }

    function test_HappyPath_AnhoerungSchliessen() public {
        bytes32 dossierID = _setupBisAnhoerung();

        vm.warp(block.timestamp + 31 days);

        vm.prank(kanzlei);
        workflow.schliesseAnhoerung(dossierID);

        (WorkflowPFV.Status status,,,,,,, ) = workflow.getDossierStatus(dossierID);
        assertEq(uint(status), uint(WorkflowPFV.Status.AnhoerungAbgeschlossen));
    }

    function test_HappyPath_OhneEroerterung() public {
        bytes32 dossierID = _setupBisAbwaegung();

        (WorkflowPFV.Status status,,,,,,, ) = workflow.getDossierStatus(dossierID);
        assertEq(uint(status), uint(WorkflowPFV.Status.InAbwaegung));
    }

    function test_HappyPath_MitEroerterung() public {
        bytes32 dossierID = _setupBisAnhoerung();

        vm.warp(block.timestamp + 31 days);

        vm.prank(kanzlei);
        workflow.schliesseAnhoerung(dossierID);

        vm.prank(bearbeitungsteam);
        workflow.entscheideEroeterterung(dossierID, true);

        vm.prank(kanzlei);
        workflow.starteEroeterterung(dossierID);

        vm.prank(kanzlei);
        workflow.schliesseEroeterterung(dossierID);

        (WorkflowPFV.Status status,,,,,,, ) = workflow.getDossierStatus(dossierID);
        assertEq(uint(status), uint(WorkflowPFV.Status.InAbwaegung));
    }

    function test_HappyPath_BeschlussErteilen() public {
        bytes32 dossierID = _setupBisAbwaegung();

        vm.prank(sachbereich);
        workflow.erteileBeschluss(dossierID, testBeschlussHash);

        (WorkflowPFV.Status status,,,,,, bool beschlussErteilt, uint256 tokenId) =
            workflow.getDossierStatus(dossierID);

        assertEq(uint(status), uint(WorkflowPFV.Status.BeschlussErteilt));
        assertTrue(beschlussErteilt);
        assertEq(workflow.ownerOf(tokenId), vorhabentraeger);
    }

    function test_HappyPath_DokumentHistory() public {
        bytes32 dossierID = _setupBisVollstaendig();

        (bytes32[] memory hashes, uint256[] memory timestamps) =
            workflow.getDokumentHistory(dossierID);

        assertEq(hashes.length, 1);
        assertEq(hashes[0], testDokumentHash);
        assertEq(timestamps.length, 1);
    }

    // ==================== NEGATIVE TESTS: VERSPAETETE EINWENDUNGEN ====================

    function test_Fail_EinwendungNachFristablauf() public {
        bytes32 dossierID = _setupBisAnhoerung();

        vm.prank(kanzlei);
        workflow.registriereEinwender(buerger, dossierID);

        // Frist ablaufen lassen
        vm.warp(block.timestamp + 31 days);

        bytes32 einwendungHash = keccak256("EINWENDUNG_VERSPAETET");
        vm.prank(buerger);
        vm.expectRevert();
        workflow.einwendungEinreichen(dossierID, einwendungHash);
    }

    function test_Fail_NachbesserungNachFristablauf() public {
        vm.prank(vorhabentraeger);
        bytes32 dossierID = workflow.dossierEinreichen(testDokumentHash);

        vm.prank(sachbereich);
        workflow.pruefeVollstaendigkeit(dossierID, false);

        // Nachbesserungsfrist ablaufen lassen
        vm.warp(block.timestamp + 31 days);

        bytes32 neuerHash = keccak256("NACHBESSERUNG_VERSPAETET");
        vm.prank(vorhabentraeger);
        vm.expectRevert();
        workflow.nachbesserungEinreichen(dossierID, neuerHash);
    }

    function test_Fail_AnhoerungVorFristablauf() public {
        bytes32 dossierID = _setupBisAnhoerung();

        // Noch keine 30 Tage vergangen
        vm.prank(kanzlei);
        vm.expectRevert();
        workflow.schliesseAnhoerung(dossierID);
    }

    function test_Fail_ToebNachFristablauf() public {
        bytes32 dossierID = _setupBisAnhoerung();

        // TÖB-Frist ablaufen lassen
        vm.warp(block.timestamp + 31 days);

        bytes32 stellungnahmeHash = keccak256("TOEB_VERSPAETET");
        vm.prank(toeb);
        vm.expectRevert();
        workflow.toebStellungnahmeEinreichen(dossierID, stellungnahmeHash);
    }

    // ==================== NEGATIVE TESTS: UNBERECHTIGTE ZUGRIFFE ====================

    function test_Fail_UnbefugterReichtDossierEin() public {
        vm.prank(unbefugter);
        vm.expectRevert();
        workflow.dossierEinreichen(testDokumentHash);
    }

    function test_Fail_UnbefugterPrueftVollstaendigkeit() public {
        vm.prank(vorhabentraeger);
        bytes32 dossierID = workflow.dossierEinreichen(testDokumentHash);

        vm.prank(unbefugter);
        vm.expectRevert();
        workflow.pruefeVollstaendigkeit(dossierID, true);
    }

    function test_Fail_VorhabentraegerStartetAnhoerung() public {
        bytes32 dossierID = _setupBisVollstaendig();

        vm.prank(vorhabentraeger);
        vm.expectRevert();
        workflow.starteAnhoerung(dossierID, 30, 30);
    }

    function test_Fail_UnbefugterErteiltBeschluss() public {
        bytes32 dossierID = _setupBisAbwaegung();

        vm.prank(unbefugter);
        vm.expectRevert();
        workflow.erteileBeschluss(dossierID, testBeschlussHash);
    }

    function test_Fail_UnregistrierterBuergerEinwendung() public {
        bytes32 dossierID = _setupBisAnhoerung();

        // Buerger wurde NICHT registriert
        bytes32 einwendungHash = keccak256("EINWENDUNG_UNBERECHTIGT");
        vm.prank(buerger);
        vm.expectRevert();
        workflow.einwendungEinreichen(dossierID, einwendungHash);
    }

    function test_Fail_FalscherVorhabentraegerNachbesserung() public {
        vm.prank(vorhabentraeger);
        bytes32 dossierID = workflow.dossierEinreichen(testDokumentHash);

        vm.prank(sachbereich);
        workflow.pruefeVollstaendigkeit(dossierID, false);

        // Anderer VT versucht nachzubessern
        address andererVT = makeAddr("andererVT");
        workflow.grantRoleToAddress(workflow.VORHABENTRAEGER_ROLE(), andererVT);

        bytes32 neuerHash = keccak256("NACHBESSERUNG_FALSCHER_VT");
        vm.prank(andererVT);
        vm.expectRevert();
        workflow.nachbesserungEinreichen(dossierID, neuerHash);
    }

    // ==================== NEGATIVE TESTS: FALSCHER STATUS ====================

    function test_Fail_PhasenwechselOhneGate() public {
        vm.prank(vorhabentraeger);
        bytes32 dossierID = workflow.dossierEinreichen(testDokumentHash);

        // Direkt Anhoerung starten ohne Vollstaendigkeitspruefung
        vm.prank(kanzlei);
        vm.expectRevert();
        workflow.starteAnhoerung(dossierID, 30, 30);
    }

    function test_Fail_BeschlussOhneAbwaegung() public {
        bytes32 dossierID = _setupBisAnhoerung();

        vm.prank(sachbereich);
        vm.expectRevert();
        workflow.erteileBeschluss(dossierID, testBeschlussHash);
    }

    function test_Fail_DoppelteEinreichung() public {
        vm.prank(vorhabentraeger);
        workflow.dossierEinreichen(testDokumentHash);

        // Zweite Einreichung mit leerem Hash
        vm.prank(vorhabentraeger);
        vm.expectRevert();
        workflow.dossierEinreichen(bytes32(0));
    }

    // ==================== EDGE CASES ====================

    function test_Edge_NachbesserungMoeglich() public {
        vm.prank(vorhabentraeger);
        bytes32 dossierID = workflow.dossierEinreichen(testDokumentHash);

        vm.prank(sachbereich);
        workflow.pruefeVollstaendigkeit(dossierID, false);

        (WorkflowPFV.Status status,, uint8 runden,,,,,) =
            workflow.getDossierStatus(dossierID);
        assertEq(uint(status), uint(WorkflowPFV.Status.NachbesserungErforderlich));
        assertEq(runden, 1);

        bytes32 neuerHash = keccak256("NACHBESSERUNG_V2");
        vm.prank(vorhabentraeger);
        workflow.nachbesserungEinreichen(dossierID, neuerHash);

        (WorkflowPFV.Status statusNach,,,,,,, ) = workflow.getDossierStatus(dossierID);
        assertEq(uint(statusNach), uint(WorkflowPFV.Status.InPruefung));
    }

    function test_Edge_PlanaenderungUnwesentlich() public {
        bytes32 dossierID = _setupBisAnhoerung();

        bytes32 neuerPlanHash = keccak256("PLAN_AENDERUNG_V2");
        vm.prank(vorhabentraeger);
        workflow.planaenderungEinreichen(dossierID, neuerPlanHash, "Geringfuegige Anpassung");

        address[] memory neueBetroffene = new address[](0);
        vm.prank(bearbeitungsteam);
        workflow.planaenderungPruefen(
            dossierID,
            0,
            WorkflowPFV.Planaenderungstyp.Unwesentlich,
            neueBetroffene
        );

        (WorkflowPFV.Status status,,,,,,, ) = workflow.getDossierStatus(dossierID);
        assertEq(uint(status), uint(WorkflowPFV.Status.InAnhoerung));
    }

    function test_Edge_BeschlussNFTNichtUebertragbar() public {
        bytes32 dossierID = _setupBisAbwaegung();

        vm.prank(sachbereich);
        workflow.erteileBeschluss(dossierID, testBeschlussHash);

        (,,,,,, , uint256 tokenId) = workflow.getDossierStatus(dossierID);

        // Transfer soll fehlschlagen (Soulbound Token)
        vm.prank(vorhabentraeger);
        vm.expectRevert();
        workflow.transferFrom(vorhabentraeger, unbefugter, tokenId);
    }

    function test_Edge_FristablaufAblehnungTrigger() public {
        vm.prank(vorhabentraeger);
        bytes32 dossierID = workflow.dossierEinreichen(testDokumentHash);

        vm.prank(sachbereich);
        workflow.pruefeVollstaendigkeit(dossierID, false);

        // Frist ablaufen lassen
        vm.warp(block.timestamp + 31 days);

        workflow.pruefeFrist(dossierID);

        (WorkflowPFV.Status status,,,,,,, ) = workflow.getDossierStatus(dossierID);
        assertEq(uint(status), uint(WorkflowPFV.Status.Abgelehnt));
    }

    function test_Edge_MehrereEinwendungen() public {
        bytes32 dossierID = _setupBisAnhoerung();

        address buerger2 = makeAddr("buerger2");
        address buerger3 = makeAddr("buerger3");

        vm.prank(kanzlei);
        workflow.registriereEinwender(buerger, dossierID);
        vm.prank(kanzlei);
        workflow.registriereEinwender(buerger2, dossierID);
        vm.prank(kanzlei);
        workflow.registriereEinwender(buerger3, dossierID);

        vm.prank(buerger);
        workflow.einwendungEinreichen(dossierID, keccak256("EINWENDUNG_1"));
        vm.prank(buerger2);
        workflow.einwendungEinreichen(dossierID, keccak256("EINWENDUNG_2"));
        vm.prank(buerger3);
        workflow.einwendungEinreichen(dossierID, keccak256("EINWENDUNG_3"));

        (,,, uint256 anzahlEinwendungen,,,, ) = workflow.getDossierStatus(dossierID);
        assertEq(anzahlEinwendungen, 3);
    }
}
