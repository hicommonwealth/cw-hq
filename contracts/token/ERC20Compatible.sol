/*
 * Declare the ERC20Compatible interface in order to handle ERC20 tokens transfers
 * to and from the Mixer. Note that we only declare the functions we are interested in,
 * namely, transferFrom() (used to do a Deposit), and transfer() (used to do a withdrawal)
**/
contract ERC20Compatible {
    function transferFrom(address from, address to, uint256 value) public;
    function transfer(address to, uint256 value) public;
}