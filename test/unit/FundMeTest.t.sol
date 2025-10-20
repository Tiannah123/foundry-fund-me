// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user"); // made a dommie person here
    uint256 constant SEND_VALUE = 0.1 ether; // 100000000000000000
    uint256 constant STARTING_BALANCE = 10 ether; // gave our dommie USER some money
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
        console.log(fundMe.MINIMUM_USD());
    }

    function testOwnerIsMsgSender() public {
        console.log(fundMe.getOwner());
        console.log(msg.sender);
        assertEq(fundMe.getOwner(), msg.sender);
        // us -> fundMeTest -> FundMe
        // We are not the one calling the contract, fundMeTest is the one calling the FundMe contract
    }

    // Types of Testing - What can we do to work with addresses outside our system?
    // Unit - testing a specific part of our code
    // Integration - testing how code works with other part of our code
    // Forked - testing our code on a simulated real environment
    // Staging - testing our code in a real environment that is not production

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); // heyy the next line should revert
        fundMe.fund(); // sent 0 value which is less that the minimum value
    }

    function testUpdatesFundedDataStructure() public {
        vm.prank(USER); // the transaction will now be sent by this person
        fundMe.fund{value: SEND_VALUE}(); // sent a value grater that the minimum value - 5

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddFundersToArrayOfFunders() public {
        vm.prank(USER); // our user
        fundMe.fund{value: SEND_VALUE}(); // she funded makes her a funder

        address funder = fundMe.getFunder(0); // check if the address of the funder if she is there
        assertEq(funder, USER); // making sure she is there
    }

    function testOnlyOwnerCanWithdraw() public { // this is testing to see if the modifier is working correctly
        vm.prank(USER); // this USER is not the owner of the contract. this person didn't deploy the contract
        fundMe.fund{value: SEND_VALUE}();

        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdrawEasyWay() public funded { // easy way to test this with modifier
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithSingleFunder() public funded {
        // Arrange
        // We check to see what's our balance before calling the withdraw function
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders () public funded {
        // Arrange
        uint160 numberOfFunders = 10; // uint160 is used when it comes to addresses
        uint160 startingFunderIndex = 1;
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE); // this means we are pranking it
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        uint256 gasStart = gasleft(); // gasleft(); - this is a built in function in solidity to tell you how much gas left
        vm.txGasPrice(GAS_PRICE); // this is to simulate it actually using gas instead of defaulting to 0
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);

        //Asert
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        // Arrange
        uint160 numberOfFunders = 10; // uint160 is used when it comes to addresses
        uint160 startingFunderIndex = 1;
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE); // this means we are pranking it
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        uint256 gasStart = gasleft(); // gasleft(); - this is a built in function in solidity to tell you how much gas left
        vm.txGasPrice(GAS_PRICE); // this is to simulate it actually using gas instead of defaulting to 0
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);

        //Asert
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }
}