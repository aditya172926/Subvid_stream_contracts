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
    uint256 internal movieId = 0;
    address constant cUSD = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    struct MovieStream {
        uint256 streamId;
        address owner;
        string title;
        string description;
        string movieUrl;
        bool requiresSubscription;
    }

    address[] signedUp;
    mapping (address => bool) public checkedSignedup;

    // mapping to track if subscribed or not
    // content_creator_address => user address => subscription endtime, ie block.timestamp + subscription duration
    mapping(address => mapping(address => uint256)) public subscribed;
    mapping(address => MovieStream[]) public myUploadedMovies; // showing content created corresponding to one's address
    mapping(address => uint256) public tokensEarned; // the amount of money earned by the creators via subscriptions.
    mapping(address => address[10]) public mySubscriptions; // users address => content creators address to which I have subscribed to

    event ContentAdded(address indexed owner, uint256 movieId);
    event UserSubscribed(address indexed user, address subscribedTo, uint256 duration, uint256 amount);
    event SubscriptionEnded(address indexed user, address subscribedTo);

    // function to add content and signup
    function addContent(
        string memory _title,
        string memory _description,
        string memory _movieUrl,
        bool _requiresSubscription
    ) public {
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

    // A list of all content creators on platform
    function getContentCreators() public view returns (address[] memory) {
        return signedUp;
    }

    // get users uploaded content
    function getMyUploadedMovies(address _user)
        public
        view
        returns (MovieStream[] memory)
    {
        return myUploadedMovies[_user];
    }

    // Subscribe to view the content by paying the fee to the creator
    function subscribeMovie(address _user, uint256 _duration, uint256 _amount) public payable {
        require(getSubscriptionStatus(_user), "You have already subscribed");
        require(
            IERC20Token(cUSD).transferFrom(msg.sender, _user, _amount), "Transfer failed"
        );
        tokensEarned[_user] = tokensEarned[_user] + _amount;
        subscribed[_user][msg.sender] = block.timestamp + (_duration * 1 seconds);
        emit UserSubscribed(msg.sender, _user, _duration, _amount);
    }

    // get my subscription status for a particular content creator
    function getSubscriptionStatus(address _user) public view returns (bool) {
        if (block.timestamp > subscribed[_user][msg.sender]) {
            return true; // subscription finished
        }
        return false; // subscription valid
    }

    // total number of content uploaded
    function totalContent() public view returns (uint256) {
        return movieId;
    }

    // check your total earnings from subscriptions
    function checkEarnings() public view returns (uint256) {
        return tokensEarned[msg.sender];
    }
}
