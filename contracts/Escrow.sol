//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(
        address _from,
        address _to,
        uint256 _id
    ) external;
}

contract Escrow {
    address public lender;
    address public inspector;
    address payable public seller; 
    address public nftAddress; 

    modifier onlyBuyer(uint256 _nftID) {
        require(msg.sender == buyer[_nftID], "Only buyer can call this method");
        _;
    }

    modifier onlySeller(){
        require(msg.sender == seller, "Only seller can call this method");
        _;
    }

    modifier onlyInspector() {
        require(msg.sender == inspector, "Only inspector can call this method");
        _;
    }

    mapping(uint256 => bool) public isListed;
    mapping(uint256 => uint256) public purchasePrice; 
    mapping(uint256 => uint256) public escrowAmount;  
    mapping(uint256 => address) public buyer;  
    mapping(uint256 => bool) public inspectionPassed;
    mapping(uint256 => mapping(address => bool)) public approval;

    constructor(
        address _nftAddress, 
        address payable _seller, 
        address _inspector, 
        address _lender)
        {
        nftAddress = _nftAddress;
        seller = _seller;
        inspector = _inspector;
        lender = _lender;
    }



    function list(
        uint256 _nftID, 
        address _buyer, 
        uint256 _purchasePrice, 
        uint256 _escrowAmount 
        ) public payable onlySeller {
        //transfer nft from seller to this contract 
        IERC721(nftAddress).transferFrom(msg.sender, address(this), _nftID); 

        isListed[_nftID] = true;
        purchasePrice[_nftID] = _purchasePrice;
        escrowAmount[_nftID] = _escrowAmount; 
        buyer[_nftID] = _buyer; 
    }

    //put under contract (only buyer- payable escrow) downpayment from the buyer
    function depositEarnest(uint256 _nftID) public payable onlyBuyer(_nftID) {
        require(msg.value >= escrowAmount[_nftID]);
    }

    // update inspection status (only inspectors)
    function updateInspectionStatus(uint256 _nftID, bool _passed)
        public
        onlyInspector
{
    inspectionPassed[_nftID] = _passed;
}

    //approve sale
    function approveSale(uint256 _nftID) public {
        approval[_nftID][msg.sender] = true;
    }

    
    //finalize sale
    //require inspection status 
    //require sale to be authorized
    //require funds to be correct amount 
    //transfer NFT to buyer
    //transfer funds to seller
    function finalizeSale(uint256 _nftID) public {
        require(inspectionPassed[_nftID]);
        require(approval[_nftID][buyer[_nftID]]);
        require(approval[_nftID][seller]);
        require(approval[_nftID][lender]);
        require(address(this).balance >= purchasePrice[_nftID]);

        (bool success, ) = payable(seller).call{value: address(this).balance}("");
        require(success);

         IERC721(nftAddress).transferFrom(address(this), buyer[_nftID ], _nftID); 

    }
    //cancel sale (handle earnest deposit)
    //if inspection status is not approved, refund. Otherwise send to seller
    function cancelSale(uint256 _nftID) public {
        if (inspectionPassed[_nftID] == false){
            payable(buyer[_nftID]).transfer(address(this).balance);
        } else {
            payable(seller).transfer(address(this).balance);
        }
    }

    receive() external payable {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

}

