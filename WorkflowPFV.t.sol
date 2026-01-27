// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/WorkflowPFV.sol";

/**
 * @title WorkflowPFVTest
 * @notice Test Suite für WorkflowPFV Smart Contract
 * @dev Tests decken Happy Path, Negative Tests, Edge Cases und Access Control ab
 */
contract WorkflowPFVTest is Test {
    
    WorkflowPFV public workflow;
    
    // Test Accounts
    address public sachbereich1;
    address public vorhabentraeger;
    address public toeb;
    address public fachpruefer;
    address public buerger;
    
    // Test Daten
    bytes32 public testDossierId;
    bytes32 public testMerkleRoot;
    
    function setUp() public {
        // Accounts erstellen
        sachbereich1 = address(this);
        vorhabentraeger = makeAddr("vorhabentraeger");
        toeb = makeAddr("toeb");
        fachpruefer = makeAddr("fachpruefer");
        buerger = makeAddr("buerger");
        
        // Contract deployen
        workflow = new WorkflowPFV();
        
        // Rollen zuweisen
        workflow.rolleZuweisen(vorhabentraeger, WorkflowPFV.Role.Vorhabentraeger);
        workflow.rolleZuweisen(toeb, WorkflowPFV.Role.Toeb);
        workflow.rolleZuweisen(fachpruefer, WorkflowPFV.Role.Fach);
        
        // Test Daten
        testDossierId = keccak256("TEST_VERFAHREN_001");
        testMerkleRoot = keccak256("MERKLE_ROOT_PLANUNTERLAGEN");
    }
    
    /*//////////////////////////////////////////////////////////////
                         DEPLOYMENT TESTS
    //////////////////////////////////////////////////////////////*/
    
    function test_Deployment() public {
        // Deployer sollte Sachbereich1PF-Rolle haben
        assertEq(uint(workflow.getRolle(sachbereich1)), uint(WorkflowPFV.Role.Sachbereich1PF));
    }
    
    /*//////////////////////////////////////////////////////////////
                      ROLLENVERWALTUNG TESTS
    //////////////////////////////////////////////////////////////*/
    
    function test_RolleZuweisen() public {
        address neuerAccount = makeAddr("neuer");
        workflow.rolleZuweisen(neuerAccount, WorkflowPFV.Role.Fach);
        
        assertEq(uint(workflow.getRolle(neuerAccount)), uint(WorkflowPFV.Role.Fach));
    }
    
    function testFail_RolleZuweisen_OhneRechte() public {
        vm.prank(buerger);
        workflow.rolleZuweisen(makeAddr("jemand"), WorkflowPFV.Role.Fach);
    }
    
    /*//////////////////////////////////////////////////////////////
                    VERFAHREN EINREICHUNG TESTS
    //////////////////////////////////////////////////////////////*/
    
    function test_VerfahrenEinreichen() public {
        vm.prank(vorhabentraeger);
        workflow.verfahrenEinreichen(testDossierId, testMerkleRoot);
        
        WorkflowPFV.Verfahren memory v = workflow.getVerfahren(testDossierId);
        
        assertEq(v.dossierId, testDossierId);
        assertEq(uint(v.status), uint(WorkflowPFV.Status.Einreichung));
        assertEq(v.vorhabentraeger, vorhabentraeger);
        assertEq(v.merkleRoot, testMerkleRoot);
        assertTrue(v.einreichungsDatum > 0);
    }
    
    function testFail_VerfahrenEinreichen_OhneRolle() public {
        vm.prank(buerger);
        workflow.verfahrenEinreichen(testDossierId, testMerkleRoot);
    }
    
    function testFail_VerfahrenEinreichen_DoppelteID() public {
        vm.startPrank(vorhabentraeger);
        workflow.verfahrenEinreichen(testDossierId, testMerkleRoot);
        workflow.verfahrenEinreichen(testDossierId, testMerkleRoot); // Sollte fehlschlagen
        vm.stopPrank();
    }
    
    function test_GetAnzahlVerfahren() public {
        assertEq(workflow.getAnzahlVerfahren(), 0);
        
        vm.prank(vorhabentraeger);
        workflow.verfahrenEinreichen(testDossierId, testMerkleRoot);
        
        assertEq(workflow.getAnzahlVerfahren(), 1);
    }
    
    /*//////////////////////////////////////////////////////////////
                    WORKFLOW GATES TESTS (TODO)
    //////////////////////////////////////////////////////////////*/
    
    // TODO: Tests für Phasenübergänge
    // - test_VollstaendigkeitPruefen_HappyPath()
    // - test_AuslegungStarten_HappyPath()
    // - test_EinwendungEinreichen_Fristgerecht()
    // - test_EinwendungEinreichen_Verspaetet()
    // - test_AbwaegungAbschliessen_HappyPath()
    // - test_BeschlussErstellen_HappyPath()
    // - test_RechtskraftFeststellen_HappyPath()
    
    // TODO: Negative Tests
    // - testFail_Phasenwechsel_OhneGate()
    // - testFail_Phasenwechsel_UngueltigeTransition()
    
    // TODO: Edge Cases
    // - test_Planaenderung_WaehrendAuslegung()
    // - test_MaximaleEinwendungen()
}
