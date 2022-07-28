//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";

interface IERC20Token {
    function transfer(address, uint256) external returns (bool);

    function approve(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract SubscribeMovie {
    uint256 private movieId = 0;
    address constant cUSD = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    struct MovieStream {
        uint256 streamId;
        address owner;
        string title;
        string description;
        string movieUrl;
        bool requiresSubscription;
    }

    enum Tiers {
        Unsubscribed,
        Bronze,
        Silver,
        Gold
    }

    address[] private signedUp;
    mapping(address => bool) public checkedSignedup;

    // mapping to track if subscribed or not
    // content_creator_address => user address => subscription endtime, ie block.timestamp + subscription duration
    mapping(address => mapping(address => uint256)) public subscribed;
    mapping(address => MovieStream[]) private myUploadedMovies; // showing content created corresponding to one's address
    mapping(address => uint256) public tokensEarned; // the amount of money earned by the creators via subscriptions.
    // keeps track of the tier subscribed for a creator of a user
    mapping(address => mapping(address => uint256)) public subscribedTier;
    event ContentAdded(address indexed owner, uint256 movieId);
    event UserSubscribed(
        address indexed user,
        address subscribedTo,
        uint256 duration,
        uint256 amount
    );
    event SubscriptionUpgraded(
        address indexed user,
        address subscribedTo,
        uint256 previousTier,
        uint256 newTier
    );

    /// @dev function to add content and signup
    function addContent(
        string calldata _title,
        string calldata _description,
        string calldata _movieUrl,
        bool _requiresSubscription
    ) external {
        require(bytes(_title).length > 0, "Empty title");
        require(bytes(_description).length > 0, "Empty description");
        require(bytes(_movieUrl).length > 0, "Empty movie url");
        if (checkedSignedup[msg.sender] == false) {
            signedUp.push(msg.sender);
            checkedSignedup[msg.sender] = true;
        }
        myUploadedMovies[msg.sender].push(
            MovieStream(
                movieId,
                msg.sender,
                _title,
                _description,
                _movieUrl,
                _requiresSubscription
            )
        );
        emit ContentAdded(msg.sender, movieId);
        movieId++;
    }

    /// @dev A list of all content creators on platform
    function getContentCreators() public view returns (address[] memory) {
        return signedUp;
    }

    /// @dev get users uploaded content
    function getMyUploadedMovies(address _user)
        public
        view
        returns (MovieStream[] memory)
    {
        require(
            _user == msg.sender || getSubscriptionStatus(_user),
            "You are not subscribed to creator"
        );
        return myUploadedMovies[_user];
    }

    /// @dev Subscribe to view the content by paying the fee to the creator
    function subscribeMovie(address _user, uint256 tier) external payable {
        require(msg.sender != _user, "You can't subscribe to yourself");
        require(!getSubscriptionStatus(_user), "You have already subscribed");
        require(
            tier == uint256(Tiers.Bronze) ||
                tier == uint256(Tiers.Silver) ||
                tier == uint256(Tiers.Gold),
            "Tier doesn't exist"
        );
        uint256 amount = 1 ether * tier;
        uint256 duration = 10 minutes * tier;
        require(
            IERC20Token(cUSD).transferFrom(msg.sender, _user, amount),
            "Transfer failed"
        );
        tokensEarned[_user] = tokensEarned[_user] + amount;
        subscribed[_user][msg.sender] = block.timestamp + duration;
        subscribedTier[_user][msg.sender] = tier;
        emit UserSubscribed(msg.sender, _user, duration, amount);
    }

    function upgradeSubscriptionStatus(address _user, uint256 tier) external {
        require(
            tier == uint256(Tiers.Silver) || tier == uint256(Tiers.Gold),
            "Tier doesn't exist"
        );
        uint256 currentTier = subscribedTier[_user][msg.sender];
        require(
            currentTier > uint256(Tiers.Unsubscribed),
            "You need to subscribe first"
        );
        require(
            currentTier < uint256(Tiers.Gold),
            "You already have the maximum tier for this creator"
        );
        uint256 amount;
        uint256 duration;
        if (currentTier == uint256(Tiers.Bronze)) {
            amount = 1 ether;
            duration = 10 minutes;
        } else {
            amount = 2 ether;
            duration = 20 minutes;
        }
        tokensEarned[_user] = tokensEarned[_user] + amount;
        subscribed[_user][msg.sender] =
            subscribed[_user][msg.sender] +
            duration;
        subscribedTier[_user][msg.sender] = tier;
        require(
            IERC20Token(cUSD).transferFrom(msg.sender, _user, amount),
            "Transfer failed"
        );

        emit SubscriptionUpgraded(
            msg.sender,
            _user,
            currentTier,
            subscribedTier[_user][msg.sender]
        );
    }

    /// @dev get a user's subscription status for a particular content creator
    function getSubscriptionStatus(address _user) public view returns (bool) {
        if (block.timestamp > subscribed[_user][msg.sender]) {
            return false; // subscription finished
        }
        return true; // subscription valid
    }

    /// @dev total number of content uploaded
    function totalContent() public view returns (uint256) {
        return movieId;
    }

    /// @dev check your total earnings from subscriptions
    function checkEarnings() public view returns (uint256) {
        return tokensEarned[msg.sender];
    }
}
