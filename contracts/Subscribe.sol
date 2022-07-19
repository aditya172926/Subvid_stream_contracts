//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";

// A celo platform for content creators. You can create your content and post it on the web.
// Using the link to your content, you can ask for subscriptions from your users to actually see
// your content after they pass the free limit.
// You will be paid on the basis of subscription model and once the user subscription ends, unless the
// user renews the subscription, they cannot view your content.

/*
We will have to make a array of users, signing up with us.
There will be another mapping which will map the users address to an array of MovieStream struct. 
It determines how the movies are uploaded for each user. 
*/

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

    enum SubscriptionDuration {
        MONTHLY,
        QUATERLY,
        HALF_YEARLY,
        ANNUALLY
    }

    struct MovieStream {
        uint256 streamId;
        address owner;
        string title;
        string description;
        string movieUrl;
        bool requiresSubscription;
        // SubscriptionDuration duration; // minimum duration 1 hour
    }

    address[] signedUp;

    // mapping to track if subscribed or not
    // content_creator_address => user address => subscription endtime, ie block.timestamp + subscription duration
    // mapping(address => mapping(address => uint256)) public subscribed; this or below one
    // movieId => user address => subscription endtime, ie block.timestamp + subscription duration
    mapping(address => mapping(address => uint256)) public subscribed;
    mapping(address => MovieStream[]) public myUploadedMovies; // showing content created corresponding to one's address
    mapping(address => uint256) public tokensEarned; // the amount of money earned by the creators via subscriptions.
    mapping(address => address[10]) public mySubscriptions; // users address => content creators address to which I have subscribed to

    event ContentAdded(address indexed owner, uint256 movieId);
    event SubscribedShow(address indexed user, address subscribedTo, uint256 duration);
    event SubscriptionEnded(address indexed user, address subscribedTo);
    event FundsWithdrawned(address indexed by, uint256 amount);

    function addContent(
        string memory _title,
        string memory _description,
        string memory _movieUrl,
        bool _requiresSubscription
    ) public {
        signedUp.push(msg.sender);
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

    function getContentCreators() public view returns (address[] memory) {
        return signedUp;
    }

    function getSusbcribedMovies(address _user)
        public
        view
        returns (MovieStream[] memory)
    {
        return myUploadedMovies[_user];
    }

    function subscribeMovie(address _user) public {
        // pay the fee to the owner or the contract. If contract, then After sometime we can send it to the owner. Just in case the user
        // decides to cancle subscription and needs a refund
        require(getSubscriptionStatus(_user), "You are already subscribed");
        IERC20Token(cUSD).transferFrom(msg.sender, address(this), 5); //sending money from subscriber to the contract
        subscribed[_user][msg.sender] = block.timestamp + 50 seconds;
    }

    function cancleSubscription(address _user) public {
        // create a cancle window. Within this window the user can cancle the subscription, but not after this window period.
        require(
            subscribed[_user][msg.sender] != 0,
            "There is no subscription for this"
        );
        // refund the money. For this the cUSD will have to be stored in the contract for sometime until the cancle duration is crossed.
        // Then the amount can be transferred to the owner. We can make the contract act as an escrow
        subscribed[_user][msg.sender] = 0;
    }

    function getSubscriptionStatus(address _user) public view returns (bool) {
        if (block.timestamp > subscribed[_user][msg.sender]) {
            return false; // subscription finished
        }
        return true; // subscription valid
    }

    function totalContent() public view returns (uint256) {
        return movieId;
    }

    function checkEarnings() public view returns (uint256) {
        return tokensEarned[msg.sender];
    }

    // after sometime the content creator can withdraw their funds from the contract
    function withdrawFunds() public {
        require(
            tokensEarned[msg.sender] > 0,
            "There is nothing to be withdrawned"
        );
        IERC20Token(cUSD).transferFrom(
            address(this),
            msg.sender,
            tokensEarned[msg.sender]
        );
        emit FundsWithdrawned(msg.sender, tokensEarned[msg.sender]);
    }

    function binarySearch(address[] memory _user) public pure returns (uint256) {
        return 5;
    }
}
