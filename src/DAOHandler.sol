// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Token.sol";



error ZeroAddress();
error EmptyURI();
error BlockedTransfer();
contract DAOHandler is ERC721, ERC721URIStorage, Ownable {
    /**
     * @dev Private variable to store the DAO token contract instance.
    */
    DAOToken private _token_Contract;

    /**
     * @dev Private variable to track the number of tokens minted.
     */
    uint256 public _tokenIds;

   
    // Mapping of registered NGO addresses to their names
    mapping(address => uint256) public ngoRegistrationNo;
    
    //Mapping of NGO Owner to create proposals
    mapping(uint256 => bool) public ngoNumberExist;
    
    //Mapping of NGO Owner to create proposals
    mapping(uint256 => address) public ngoOwner;

    //Mapping for registeration of NGO check
    mapping(uint256 => bool) public registeredNGOs;


    // Mapping of registered NGO registeratioNo to yay votes
    mapping(uint256 => uint256) public infavourVotes;

    // Mapping of registered NGO registeratioNo to nay votes
    mapping(uint256 => uint256) public againstVotes;

    // Mapping of voters to whether they have voted for an NGO or not
    mapping(address => mapping(uint256 => bool)) public ngoVoters;

    // Mapping to store NFT ID against NGO registration numbers
    mapping(uint256 => uint256) public registeredCampaign;

    mapping(uint256 => bool) public acceptedCampaigns;

    // Mapping to store NFT IDs against NGO registration numbers
    mapping(uint256 => uint256[]) public ngoAllCampaigns;

    //mapping to keep endTimeforvote for a campaign
    mapping(uint256 => uint256) public campaignEndTime;

    //mapping to keep the beneficiary according to the campign
    mapping(uint256 => uint256) public ngototalBeneficiary;

    // Mapping to store maximum donation for a single project
    mapping(uint256 => uint256) public maxCampaignDonation;

      // Mapping campaign donation that is recieved for each campaign
    mapping(uint256 => uint256) public recieved_Donation;

      // mapping to store that the beneficiary has 1 voucher of the campaign
    mapping(address => mapping(uint256 => uint256))
        public beneficiaryHasVoucherInCampaign;

    // Mapping to store the price of voucher in a specific campaign
    mapping(address => mapping(uint256 => uint256)) public priceOfVoucher;

    // Mapping of voters to whether they have voted for a campaign or not
    mapping(address => mapping(uint256 => bool)) public campaignvoters;

         // Mapping of registered NGO addresses to yay votes
    mapping(uint256 => uint256) public campaignFavourVotes;

    // Mapping of registered NGO addresses to nay votes
    mapping(uint256 => uint256) public campaignAgainstVotes;

    // Mapping to track claimed funds for each campaign
    mapping(uint256 => uint256) public claimedFunds;
        /**
        * Modifier: daoTokenHolderOnly
        *
        * Checks if caller holds DAO Tokens.
        *
        * Requirements:
        * - Caller must hold at least 1 DAO Token.
        *
        * Usage:
        * - Apply to functions accessible only to DAO Token holders.
        */
        // Modifier for DAO Token holders only
        modifier daoTokenHolderOnly() {
            require(
                _token_Contract.balanceOf(msg.sender) >= 1*10**18,
                "Only DAO Token holder can vote."
            );
            _;
        }
        

            /**
            * Modifier that checks if a campaign is accepted.
            * 
            * @param _campaignID The ID of the campaign to check.
            * 
            * Requirements:
            * - The campaign must be accepted.
            */
            modifier onlyAcceptedCampaign(uint256 _campaignID) {
                require(acceptedCampaigns[_campaignID], "CAMPAIGN_NOT_ACCEPTED");
                _;
            }

        modifier onlyRegisteredNGO(uint256 _ngoRegisterationNO) {
            require(registeredNGOs[_ngoRegisterationNO], "NGO_NOT_REGISTERED");
            _;
        }
        
        modifier registeredNGOExists(uint256 _ngoRegisterationNO) {
            require(ngoNumberExist[_ngoRegisterationNO], "NGO registration does not exist.");
            _;
        }


        modifier onlyNotRegisteredNGO(uint256 _ngoRegisterationNO) {
            require(!registeredNGOs[_ngoRegisterationNO], "NGO already registered.");
            _;
        }



         /**
     * Modifier: onlyVotingPeriod
     * 
     * Checks if the voting period for a given token ID has not ended.
     * 
     * @param _tokenId The ID of the token to check the voting period for.
     * 
     * Requirements:
     * - The current block timestamp must be less than the end time of the voting period for the token.
     * - Otherwise, it reverts with the error message "VOTING_PERIOD_ENDED".
     */
    modifier onlyVotingPeriod(uint256 _tokenId) {
        require(
            block.timestamp < campaignEndTime[_tokenId],
            "VOTING_PERIOD_ENDED"
        );
        _;
    }

    modifier notDuringVotingPeriod(uint256 _tokenId) {
    require(!(block.timestamp < campaignEndTime[_tokenId]), "Cannot execute during voting period");
    _;
    }
        /**
     * Modifier: notAlreadyVoted
     * 
     * Description: Checks if the sender has already voted for a specific token ID.
     * 
     * Parameters:
     @param _tokenId: The ID of the token being voted on.
    * 
    * Requirements:
    * - The sender must not have already voted for the given token ID.
    * 
    * Error:
    * - ALREADY_VOTED: The sender has already voted for the given token ID.
    */
    // Modifier to check if the address has not already voted for the campaign
    modifier notAlreadyVoted(uint256 _tokenId) {
        require(!campaignvoters[msg.sender][_tokenId], "ALREADY_VOTED");
        _;
    }
            /**
     * Modifier: alreadyVotedNGO
     * 
     * Description: Checks if the sender has already voted for a specific NGO registration number.
     * 
     * Parameters:
     * - _ngoRegisterationNO: The registration number of the NGO.
     * 
     * Requirements:
     * - The sender must not have already voted for the specified NGO registration number.
     * 
     * Error:
     * - ALREADY_VOTED: The sender has already voted for the specified NGO registration number.
     */
    //Modifier to check if has voted or not
    modifier alreadyVotedNGO(uint256 _ngoRegisterationNO) {
        require(!ngoVoters[msg.sender][_ngoRegisterationNO], "ALREADY_VOTED");
        _;
    }

    /**
     * @dev Event triggered when an NGO is registered.
     * @param ngoAddress The address of the registered NGO.
     * @param _ngoRegisterationNO The registration number of the NGO.
     */

    //Event for Registeration process of NGO
    event registerationNGO(
        address indexed ngoAddress,
        uint256 indexed _ngoRegisterationNO,
        bool isCompletelyRegistered
    );

    /**
     * @dev Event triggered when an NGO votes on a campaign.
     * 
     * @param _tokenId The ID of the campaign.
     * @param _voter The address of the NGO that voted.
     * @param _vote The vote (true for in favor, false for against).
     */
    //NGO vote Event
    event NGOVoted(
        uint256 indexed _tokenId,
        address indexed _voter,
        bool _vote
    );

        /**
     * @dev Event emitted when an NGO is registered.
     * @param _ngoAddress The address of the registered NGO.
     * @param _ngoRegisterationNO The registration number of the NGO.
     */
    //Event for registered NGO
    event ngoRegistered(
        address indexed _ngoAddress,
        uint256 indexed _ngoRegisterationNO
    );

    /**
     * @dev Event triggered when a campaign proposal is created.
     * 
     * @param tokenURI The URI of the token associated with the campaign proposal.
     * @param NGO_Owner The address of the NGO owner creating the proposal.
     * @param registrationNo The registration number of the NGO.
     * @param tokenId The ID of the token associated with the campaign proposal.
     * @param beneficiary The number of beneficiaries for the campaign.
     * @param endVoteTimed The end timestamp of the voting period for the campaign.
     */
    //event for campaign proposal
    event campaignProposal(
        string tokenURI,
        address NGO_Owner,
        uint256 registrationNo,
        uint256 tokenId,
        uint256 beneficiary,
        uint256 endVoteTimed
    );

        /**
     * @dev Event triggered when a campaign is voted.
     * @param _tokenId The ID of the campaign being voted.
     * @param _voter The address of the voter.
     * @param _vote The vote value (true or false).
     */
    //campaign vote event
    event campaignVoted(
        uint256 indexed _tokenId,
        address indexed _voter,
        bool _vote
    );

    /**
     * @dev Event emitted when a campaign is registered.
     * @param tokenId The ID of the campaign token.
     * @param value The boolean value indicating if the campaign is registered or not.
     */
    //event for registered campaign
    event campaignRegistered(uint256 indexed tokenId, bool value);
    
    constructor(DAOToken token) ERC721("Aidance", "Adn") Ownable(msg.sender) {
            _token_Contract = token;
        }

   /**
     * 
    Registers an NGO with the given address and registration number.
    @param _ngoRegisterationNO: The registration number of the NGO.
    */
    function registerationForNGO(uint256 _ngoRegisterationNO) external {
        require(!ngoNumberExist[_ngoRegisterationNO], "Ngo Registeration already Exist");
        require(ngoRegistrationNo[msg.sender] == 0, "Address already has a registeration");

        ngoRegistrationNo[msg.sender] = _ngoRegisterationNO;
        ngoOwner[_ngoRegisterationNO] = msg.sender;
        registeredNGOs[_ngoRegisterationNO] = false;
        ngoNumberExist[_ngoRegisterationNO] = true;

        emit registerationNGO(msg.sender, _ngoRegisterationNO,false);
    }


        /**
     * 
    Vote for an NGO.
    @param _ngoRegisterationNO: The registration number of the NGO to vote for.
    */
    function voteForNGO(
        uint256 _ngoRegisterationNO
    )
        external
        onlyNotRegisteredNGO(_ngoRegisterationNO)
        alreadyVotedNGO(_ngoRegisterationNO)
        daoTokenHolderOnly
    {
        ngoVoters[msg.sender][_ngoRegisterationNO] = true;
        infavourVotes[_ngoRegisterationNO]++;
         // Burn ERC-20 tokens
         _token_Contract.burnToken(msg.sender,1*10**18);
        emit NGOVoted(_ngoRegisterationNO, msg.sender, true);
    }
    /**
    Vote against a registered NGO.

    @param _ngoRegisterationNO: The registration number of the NGO.
     */
    function voteAgainstNGO(
        uint256 _ngoRegisterationNO
    )
        external
        onlyNotRegisteredNGO(_ngoRegisterationNO)
        alreadyVotedNGO(_ngoRegisterationNO)
        daoTokenHolderOnly
    {
        ngoVoters[msg.sender][_ngoRegisterationNO] = true;
        againstVotes[_ngoRegisterationNO]++;
          // Burn ERC-20 tokens
        _token_Contract.burnToken(msg.sender,1*10**18);
        emit NGOVoted(_ngoRegisterationNO, msg.sender, true);
    }


        /** 
    Confirm the registration of an NGO.

    @param _ngoRegisterationNO: The registration number of the NGO to be confirmed.
    @dev This function can only be called by the contract owner.
    @dev The NGO can only be confirmed if there are more in-favor votes than against votes.
    @dev Emits an 'ngoRegistered' event with the address of the NGO owner and the registration number.
    */
    function confirmRegisteration(
        uint256 _ngoRegisterationNO
    ) external onlyNotRegisteredNGO(_ngoRegisterationNO) registeredNGOExists(_ngoRegisterationNO) onlyOwner {
        require(infavourVotes[_ngoRegisterationNO] > againstVotes[_ngoRegisterationNO],"NGO can't registered as majority doesn't want");
        registeredNGOs[_ngoRegisterationNO] = true;
        emit ngoRegistered(ngoOwner[_ngoRegisterationNO], _ngoRegisterationNO);
    }

    /**
     * 
    Creates a proposal for a campaign.

    @param _votinghours: The duration of the voting period in hours.
    @param _totalBeneficiary: The total number of beneficiaries for the campaign.
    @param _ngoRegisterationNO: The registration number of the NGO creating the proposal.
    @param _tokenURI: The URI for the token associated with the proposal.
    @param _max_Donation: The maximum donation amount for the campaign.

    return: The ID of the created proposal.

    */
    function createProposal(
         uint256 _votinghours,
        uint256 _totalBeneficiary,
        uint256 _ngoRegisterationNO,
        string memory _tokenURI,
        uint256 _max_Donation
    )public onlyRegisteredNGO(_ngoRegisterationNO) returns(uint256){
        require(
            ngoOwner[_ngoRegisterationNO] == msg.sender,
            "only NGO owner can create the proposal"
        );
        uint256 timeforvote = block.timestamp + (_votinghours * 1 hours);
         if (!(msg.sender != address(0))) {
            revert ZeroAddress();
        }
         if (!(bytes(_tokenURI).length > 0)) {
            revert EmptyURI();
        }
        require(_votinghours > 0, "Voting hours must be greater than zero");
        require(_max_Donation > 0, "Max donation must be greater than zero");
        require(_totalBeneficiary > 0, "total beneficiary must be greater than zero");
        _tokenIds++;
        registeredCampaign[_tokenIds] = _ngoRegisterationNO;
        acceptedCampaigns[_tokenIds] = false;
        ngoAllCampaigns[_ngoRegisterationNO].push(_tokenIds); // Store the NFT ID in the array associated with the NGO registration number
        campaignEndTime[_tokenIds] = timeforvote;
        ngototalBeneficiary[_tokenIds] = _totalBeneficiary;
        _safeMint(msg.sender, _tokenIds);
        _setTokenURI(_tokenIds, _tokenURI);
        maxCampaignDonation[_tokenIds] = _max_Donation * (10 ** 18);
         emit campaignProposal(
            _tokenURI,
            msg.sender,
            _ngoRegisterationNO,
            _tokenIds,
            _totalBeneficiary,
            timeforvote
        );
        return _tokenIds;
    }


      /** 
    Vote for a campaign.

    This function allows a DAO token holder to vote for a specific campaign. The voter must hold a DAO token, and the voting period for the campaign must be ongoing. The voter can only vote once for a specific campaign.

    Parameters:
    - _tokenId: The ID of the campaign to vote for.

    Modifiers:
    - daoTokenHolderOnly: Only DAO token holders can call this function.
    - onlyVotingPeriod: The voting period for the campaign must be ongoing.
    - notAlreadyVoted: The voter must not have already voted for the campaign.
    */

    function voteForCampaign(
        uint256 _tokenId
    )
        external
        daoTokenHolderOnly
        onlyVotingPeriod(_tokenId)
        notAlreadyVoted(_tokenId)
    {
        campaignvoters[msg.sender][_tokenId] = true;
        campaignFavourVotes[_tokenId]++;
         // Burn ERC-20 tokens
         _token_Contract.burnToken(msg.sender,1*10**18);
        emit campaignVoted(_tokenId, msg.sender, true);
    }


    /**
    Vote against a campaign.

    This function allows a DAO token holder to vote against a specific campaign. The voter must be within the voting period and must not have already voted for the campaign. The function updates the campaign's vote count and emits a `campaignVoted` event.

    Parameters:
    * @param _tokenId :The ID of the campaign to vote against.

    Modifiers:
    - `daoTokenHolderOnly`: Only DAO token holders can call this function.
    - `onlyVotingPeriod`: The voting period for the campaign must not have ended.
    - `notAlreadyVoted`: The caller must not have already voted for the campaign.
     
     */
    function voteAgainstCampaign(
        uint256 _tokenId
    )
        external
        daoTokenHolderOnly
        onlyVotingPeriod(_tokenId)
        notAlreadyVoted(_tokenId)
    {
        campaignvoters[msg.sender][_tokenId] = true;
        campaignAgainstVotes[_tokenId]++;
          // Burn ERC-20 tokens
          _token_Contract.burnToken(msg.sender,1*10**18);
        emit campaignVoted(_tokenId, msg.sender, true);
    }



        /**
     * Confirm the acceptance of a campaign.
     *
     * @param _campaignID The ID of the campaign to confirm acceptance for.
     * @dev This function checks if the majority of votes are in favor of the campaign and if the campaign has not already been accepted.
     * If the conditions are met, the campaign is marked as accepted and an event is emitted.
     */
    function confirmAcceptCampaign(uint256 _campaignID) external notDuringVotingPeriod(_campaignID) onlyOwner{
        require(campaignFavourVotes[_campaignID] > campaignAgainstVotes[_campaignID],"Campaign cannot be accepted as majority does not want");
        require(!acceptedCampaigns[_campaignID], "CAMPAIGN_ALREADY_ACCEPTED");
        acceptedCampaigns[_campaignID] = true;
        emit campaignRegistered(_campaignID, true);
    }





     /**
    Function: makeDonation

    This function allows users to make a donation to a specific campaign.

    Parameters:
    - _campaignID: uint256 - The ID of the campaign to donate to.

    Modifiers:
    - onlyAcceptedCampaign: Ensures that the campaign is accepted and can receive donations.

    Requirements:
    - The campaign must have a maximum donation limit.
    - The total received donation amount plus the new donation amount must not exceed the maximum donation limit.
    - The donation amount must be greater than zero.

    Effects:
    - Increases the received donation amount for the specified campaign.
    - Sends the donated Ether to the contract.

    Returns: None

    Raises:
    - "This campaign has no max donations": If the campaign does not have a maximum donation limit.
    - "Insufficient Amount": If the donation amount is zero.
     */
    function makeDonation(
        uint256 _campaignID
    ) public payable onlyAcceptedCampaign(_campaignID) {
        require(
            maxCampaignDonation[_campaignID] > 0,
            "This campaign has no max donations"
        );
        require(
            recieved_Donation[_campaignID] + msg.value <=
                maxCampaignDonation[_campaignID],
            "Max Capaign Ammount Reached"
        );
        require(msg.value > 0, "Insufficient Amount");

        recieved_Donation[_campaignID] += msg.value;
        (bool sent, ) = address(this).call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }


 /**
     * Creates a voucher for a beneficiary in a campaign.
     * 
     * @param _beneficiary The address of the beneficiary.
     * @param _price The price of the voucher.
     * @param _tokenURI The URI of the token associated with the voucher.
     * @param _campaignID The ID of the campaign.
     * 
     * Requirements:
     * - The campaign must have received the maximum donation.
     * - The beneficiary must not already have a voucher for this campaign.
     * 
     * Emits a {Transfer} event to mint the voucher token for the beneficiary.
     * Sets the token URI for the voucher token.
     */
    function createVoucher(
        address _beneficiary,
        uint256 _price,
        string memory _tokenURI,
        uint256 _campaignID
    ) public onlyOwner {
        require(
        claimedFunds[_campaignID]+_price <= maxCampaignDonation[_campaignID],
        "Claimed funds plus voucher price exceed maximum donation for this campaign"
        );
        require(
            recieved_Donation[_campaignID] >= maxCampaignDonation[_campaignID],
            "Campaign has not reached its donation goal"    
            );
        require(
            beneficiaryHasVoucherInCampaign[_beneficiary][_campaignID] < 1,
            "You already have voucher of this campaign"
        );
        //ask usman to check or needed
        beneficiaryHasVoucherInCampaign[_beneficiary][_campaignID]=1;
        priceOfVoucher[_beneficiary][_campaignID] = _price;
        _tokenIds++;
        _safeMint(_beneficiary, _tokenIds);
        _setTokenURI(_tokenIds, _tokenURI);
    }

 /**
     * @notice Claims funds of a beneficiary for a specific campaign.
     * @param _beneficiary The address of the beneficiary.
     * @param _campaignID The ID of the campaign.
     * @param _vendor The address of the vendor.
     * @dev This function allows the beneficiary to claim the funds allocated to them in a campaign.
     *      It requires that the beneficiary has a voucher and a price associated with it.
     *      The function transfers the funds to the vendor's address.
     *      It also updates the beneficiary's voucher status and price to zero.
     *      If the transfer fails, an error message is thrown.
     */
    function claimFundsOfBeneficiary(
        address _beneficiary,
        uint256 _campaignID,
        address _vendor
    ) public {
        require(
            beneficiaryHasVoucherInCampaign[_beneficiary][_campaignID] == 1,
            "This beneficiary doesn't have a voucher"
        );
        require(
            priceOfVoucher[_beneficiary][_campaignID] > 0,
            "This beneficiary doesn't have a price"
        );

        uint256 claimedAmount = priceOfVoucher[_beneficiary][_campaignID];

        beneficiaryHasVoucherInCampaign[_beneficiary][_campaignID] = 0;
        priceOfVoucher[_beneficiary][_campaignID] = 0;

        (bool sent, ) = payable(_vendor).call{value: claimedAmount}("");
        require(sent, "Failed to send Ether");

        // Subtract the claimed amount from the claimed funds for the campaign
        claimedFunds[_campaignID] += claimedAmount;
    }

    /**
    *
    Updates the total number of beneficiaries for a registered NGO.

    @param _ngoRegisterationNO: The registration number of the NGO.
    @param _noOfBeneficiary: The new total number of beneficiaries.

    return: A boolean indicating whether the update was successful.
     */
    function updateTotalBeneficary(
        uint256 _campaignId,
        uint256 _noOfBeneficiary,
        uint256 _ngoRegisterationNO
    ) external onlyRegisteredNGO(_ngoRegisterationNO) returns (bool) {
        require(
            ngoOwner[_ngoRegisterationNO] == msg.sender,
            "only NGO owner can update beneficiary"
        );
        ngototalBeneficiary[_campaignId] = _noOfBeneficiary;
        return true;
    }


      /**
     * @dev Checks if the voting period for a specific token ID has ended.
     * @param _tokenId The ID of the token.
     * @return A boolean indicating whether the voting period has ended or not.
     */
    function isVotingPeriodEnded(
        uint256 _tokenId
    ) external view returns (bool) {
        return block.timestamp >= campaignEndTime[_tokenId];
    }

    /**
    Internal function to update the ownership of a token.
    @param to: The address to transfer the token ownership to.
    @param tokenId: The ID of the token to be transferred.
    @param auth: The address authorizing the transfer.
    return: The address of the previous token owner.
     */
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal virtual override returns (address) {
        address from = _ownerOf(tokenId);
        if (!(from == address(0))) {
            revert BlockedTransfer();
        }
        super._update(to, tokenId, auth);
        return from;
    }

    /**
     * @dev Checks if the contract supports a given interface.
     * @param interfaceId The interface identifier.
     * @return True if the contract supports the interface, false otherwise.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }


    /**
     * @dev Retrieves the token URI for a given token ID.
     *
     * @param tokenId The ID of the token.
     * @return The token URI associated with the token ID.
     */
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    /**
     * @dev Fallback function to receive Ether.
     */
    receive() external payable {}
}