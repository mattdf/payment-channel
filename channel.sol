pragma solidity ^0.4.24;

contract Channel {

	address public channelSender;
	address public channelRecipient;
	uint public startDate;
	uint public channelTimeout;
	mapping (bytes32 => address) signatures;

	constructor (address to, uint timeout) public payable {
		channelRecipient = to;
		channelSender = msg.sender;
		startDate = now;
		channelTimeout = timeout;
	}

	function CloseChannel(bytes32 h, uint8 v, bytes32 r, bytes32 s, uint value) public {

		address signer;
		bytes32 proof;

		// get signer from signature
		signer = ecrecover(h, v, r, s);

		// signature is invalid, throw
		require (
			signer == channelSender || signer == channelRecipient,
			"Signer not authorized."	
		);

		proof = keccak256(abi.encodePacked(this, value));

		// throws if signature is valid but doesn't match the data provided
		require (proof == h, "Data doesn't match.");

		if (signatures[proof] == 0)
			signatures[proof] = signer;
		else if (signatures[proof] != signer){
			// channel completed, both signatures provided
			require (channelRecipient.send(value), "Transfer not completed.");
			selfdestruct(channelSender);
		}

	}

	function ChannelTimeout() public {
		require (
			startDate + channelTimeout <= now,
			"Period not over yet."
		);

		selfdestruct(channelSender);
	}

}
