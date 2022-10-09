// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract MultiPartyWallet {

    event Deposit(address indexed sender, uint256 amount, uint256 balance);

    event SubmitProposal(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );

    event ConfirmProposal(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteProposal(address indexed owner, uint256 indexed txIndex);

    address[] public owners;

    mapping(address => bool) public isOwner;

    uint256 public confirmationsRequired;

    uint256 public minPercent;

    address public Admin;


    struct Proposal {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    Proposal[] public proposals;

    modifier onlyAdmin() {
        require(Admin == msg.sender, "Not Admin");
        _;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not Owner");
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < proposals.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!proposals[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    constructor(address[] memory _owners, uint256 _minPercent) {

        require(_owners.length > 0, "owners required");

        require(
            _minPercent < 100 &&
            _minPercent >= 60,
            "Invalid minimum percentage"
        );

        for (uint256 i = 0; i < _owners.length; i++) {

            address owner = _owners[i];

            require(owner != address(0), "invalid owner");

            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;

            owners.push(owner);
        }

        minPercent = _minPercent;

        confirmationsRequired = owners.length * minPercent / 100;

        Admin = msg.sender; 
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitProposal(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public onlyOwner {

        uint256 txIndex = proposals.length;

        proposals.push(
            Proposal({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitProposal(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmProposal(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Proposal storage proposal = proposals[_txIndex];

        proposal.numConfirmations += 1;

        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmProposal(msg.sender, _txIndex);
    }

    function executeProposal(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Proposal storage proposal = proposals[_txIndex];

        require(
            proposal.numConfirmations >= confirmationsRequired,
            "cannot execute tx"
        );

        (bool success, ) = proposal.to.call{value: proposal.value}(
            proposal.data
        );

        require(success, "tx failed");

        proposal.executed = true;

        emit ExecuteProposal(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Proposal storage proposal = proposals[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        proposal.numConfirmations -= 1;

        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getProposalCount() public view returns (uint256) {
        return proposals.length;
    }

    function getProposal(uint256 _txIndex)
        public
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        )
    {
        Proposal storage proposal = proposals[_txIndex];

        return (
            proposal.to,
            proposal.value,
            proposal.data,
            proposal.executed,
            proposal.numConfirmations
        );
    }

    // Admin Functions

    function removeOwner(address _toBeRemoved)
        public 
        onlyAdmin 
    {

        require(isOwner[_toBeRemoved], "Not an owner");

        for (uint i = 0; i < owners.length; i++) {

            if (_toBeRemoved == owners[i])
            {
                for (uint j = i; j < owners.length - 1; j++) {
                    owners[j] = owners[j + 1];
                }
                owners.pop();

                isOwner[_toBeRemoved] = false;
            }
        }

    }

    function addOwner(address _toBeAdded) 
        public 
        onlyAdmin 
    {

        require(!isOwner[_toBeAdded], "Already owner");

        require(_toBeAdded != address(0));

        isOwner[_toBeAdded] = true;

        owners.push(_toBeAdded);

    }

    function setMinPercent(uint256 _newMinPercent)
        public
        onlyAdmin
    {
        require(
            _newMinPercent >= 60 &&
            _newMinPercent < 100,
            "Invalid minimum percentage"
        );

        minPercent = _newMinPercent;
    }
}
Footer
