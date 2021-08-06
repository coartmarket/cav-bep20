import {Ownable, SafeMath, IBEP20} from "./CAV_Token.sol";

contract Deployment is Ownable {
    
    using SafeMath for uint256;

    IBEP20 public token;

    uint256 rate = 7200;
    uint256 maximumBuyIn = 5000000000000000000;
    uint256 timespan = 30 days * 3;

    mapping(address => bool) whitelist;
    mapping(address => uint256) maximumBuyInList;
    mapping(address => uint256) whitelistedTimeFrame;
    mapping(address => uint256) boughtLeftoverAmount;

    constructor(IBEP20 _token) public {
        token = _token;
    }

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    modifier maximumBuyInCheck() {
        require(
            msg.value <= maximumBuyIn,
            "Amount must be less than the set maximum"
        );
        require(
            (maximumBuyInList[msg.sender].add(msg.value)) <= maximumBuyIn,
            "Amount must be less than the set maximum"
        );
        _;
    }

    modifier timeFrameCheck() {
        require(
            whitelistedTimeFrame[msg.sender] <= block.timestamp,
            "Time has not passed yet"
        );
        _;
    }

    function buy() public payable onlyWhitelisted maximumBuyInCheck {
        maximumBuyInList[msg.sender] = maximumBuyInList[msg.sender].add(
            msg.value
        );
        whitelistedTimeFrame[msg.sender] = block.timestamp.add(timespan);
        uint256 amountTobuy = msg.value;

        require(msg.sender != address(0), "Sender is address zero");
        require(amountTobuy > 0, "You need to send some BNB");
        uint256 totalAmountOfTokens = amountTobuy.div(rate);
        require(
            totalAmountOfTokens <= token.balanceOf(address(this)),
            "Not enough tokens in the reserve"
        );
        token.approve(address(this), totalAmountOfTokens);
        totalAmountOfTokens = totalAmountOfTokens.div(2);
        boughtLeftoverAmount[msg.sender] = boughtLeftoverAmount[msg.sender].add(totalAmountOfTokens);
        token.transferFrom(address(this), msg.sender, totalAmountOfTokens);
    }

    function claimRemainingTokens()
        public
        payable
        onlyWhitelisted
        timeFrameCheck        
    {   
        require(msg.sender != address(0), "Sender is address zero");
        require(
            whitelistedTimeFrame[msg.sender] > 0,
            "Timeframe was not set"
        );
        require(
            boughtLeftoverAmount[msg.sender] > 0,
            "All funds already claimed"
        );
        token.approve(address(this), boughtLeftoverAmount[msg.sender]);
        token.transferFrom(address(this), msg.sender, boughtLeftoverAmount[msg.sender]);
        boughtLeftoverAmount[msg.sender] = boughtLeftoverAmount[msg.sender].sub(boughtLeftoverAmount[msg.sender]);
    }

    function addToWhitelistSingle(address addAddresses) public onlyOwner {
        whitelist[addAddresses] = true;
    }

    function addToWhitelistMultiple(address[] memory addAddresses)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < addAddresses.length; i++) {
            whitelist[addAddresses[i]] = true;
        }
    }

    function removeFromWhitelist(address remAddress) public onlyOwner {
        whitelist[remAddress] = false;
    }

    function changeRate(uint256 newRate) public onlyOwner {
        rate = newRate;
    }

    function changeMaximumBuyIn(uint256 newMaximumBuyIn) public onlyOwner {
        maximumBuyIn = newMaximumBuyIn;
    }

    function isWhitelisted(address isAddress) public view returns (bool) {
        return whitelist[isAddress];
    }
}
