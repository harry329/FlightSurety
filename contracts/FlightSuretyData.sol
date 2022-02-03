// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;


//import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
//    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false

    struct Airline {
        string name;
        uint256 amountPaid;
        bool authorityGranted;
        bool isAdded;
    }

    mapping(address => Airline) private airlines;
    uint8 constant private MINIMUM_AMOUNT = 3;
    uint256 private numberOfAirlinesWithAuthority = 0;
    uint256 private totalNumberOfAirlinesAdded = 0;

    mapping(address => FlightInfo) customerInsuranceInfo;
    struct FlightInfo {
        string flightKey;
        bool isPresent;
    }

    mapping(address => uint256) customerCreditInfo;
    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/



    event AirlineAdded(Airline airline);

    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor() public payable{
        contractOwner = msg.sender;
        Airline memory firstAirline = Airline({name: "Owner's Airline", amountPaid: msg.value, isAdded: true, authorityGranted : false});
        airlines[msg.sender] = firstAirline;
        if(msg.value > MINIMUM_AMOUNT) {
            airlines[msg.sender].authorityGranted = true;
        }
        incrementAirlineCount();
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier checkOtherAirlinesApproval(address airlineOwnerAddress) {
        require(!airlines[airlineOwnerAddress].isAdded, "Airlines is already added");
        require(airlines[msg.sender].isAdded, "Airlines is already added");
        bool checkAuthority = airlines[msg.sender].authorityGranted;
        require(checkAuthority, "Adder has authority");
        if(checkAuthority) {
            incrementAuthorizedAirlineCount();
        }
        require(totalNumberOfAirlinesAdded < 4 ||   numberOfAirlinesWithAuthority > uint8(totalNumberOfAirlinesAdded/2), "Not Approved by other airlines"  );
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function incrementAirlineCount() private {
        totalNumberOfAirlinesAdded +=1;
    }

    function incrementAuthorizedAirlineCount() private {
        numberOfAirlinesWithAuthority +=1;
    }

    function resetAuthorizedAirlineCount() private {
        numberOfAirlinesWithAuthority = 0;
    }

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner 
    {
        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline
                            (
                            address airlineOwnerAddress,
                            string memory nameOfAirline
                            )
                            external
                            requireIsOperational
                            checkOtherAirlinesApproval(airlineOwnerAddress)
                            payable
    {
        bool grantAccess = false;
        if(msg.value > MINIMUM_AMOUNT) {
            grantAccess = true;
        }
        Airline memory airline = Airline({name: nameOfAirline,amountPaid : msg.value,authorityGranted: grantAccess, isAdded : true  });
        airlines[airlineOwnerAddress] = airline;
        incrementAirlineCount();
        resetAuthorizedAirlineCount();
        emit AirlineAdded(airline);
    }


   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (
                            address customer,
                            string memory flightInfo
                            )
                            external
                            requireIsOperational
                            payable
    {
        customerInsuranceInfo[customer] = FlightInfo(flightInfo, true);
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                address customer
                                )
                                external
                                requireIsOperational
    {
        if(address(this).balance >= 2 && customerInsuranceInfo[customer].isPresent ) {
            customerCreditInfo[customer] = 2;
        }

    }

//    function _make_payable(address x) internal pure returns (address payable) {
//        address payable wallet = address(uint160(x));
//        return  wallet;
//    }

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                            address customer
                            )
                            external
                            requireIsOperational
                            payable
    {
        if(customerCreditInfo[customer] >=2) {
            customerCreditInfo[customer] -= 2;
            payable(customer).transfer(2);
        }
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund
                            (   
                            )
                            public
                            payable
    {
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    fallback() external payable {}

    receive() external payable {}

}

