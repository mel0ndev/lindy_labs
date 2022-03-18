pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2; 

//03/15 time worked: 1835 hours -- 2013 hours 
//03/16 time worked: 1801 -- 2038 hours 
//03/17 time worked: 1757 --


contract RockPaperScissors {

    struct Game {
        uint local_id; //stores each game locally so mulitple can be played at once
        bool is_active;
		bool accepted; //lets player1 know that player2 has moved  
        address player1;
        bytes32 player1_move; //a hashed secret move
        address player2;
        string player2_move; //not hashed, no need since the game resolves after player2 moves  uint pot; //the size of the pot
        uint timer; //timer is stores locally as well  
		uint pot; 
		uint rollover_pot; 
        address winner; //to read for later if needed  
    }


    mapping(uint => Game) public games;
    mapping(address => uint) public balances;
	mapping(address => bool) public in_game; 
    uint public global_id;  
    uint min_bet;

    constructor() {
        min_bet = 1 ether;
    }


    function deposit() external payable {
        require(msg.value == min_bet, "not enough ether to enter the game"); //I think this evaluates to 1e18?  

        balances[msg.sender] += msg.value;

        //I believe call is the current best way to do this?    
        (bool sent, ) = address(this).call{value: msg.value}("");
        require(sent == true, "send failed");

    }

	function withdraw() external payable {
		require(balances[msg.sender] > 0, "no balance to withdraw"); 
		require(in_game[msg.sender] == false, "can't withdraw while in a game"); 
		require(msg.value <= balances[msg.sender]);  
		
		//balances are updated at eval 	
		payable(msg.sender).transfer(msg.value); 	
	}

	//the player you're challenging, your move, a secret key, and rollover game id from a previous game, if any 
	//submit the hashed move as keccak256(abi.encodePacked("your move", secret_number_key)); 
    function start_game(address player2, bytes32 hashed_move, uint rollover_id) external {
        //increment global game count  
        global_id++;

        require(games[global_id].is_active == false, "game is already active");
        require(balances[msg.sender] >= min_bet, "balance too low to start a game");

		uint pot_size = 1 ether;  
		//check if there is rollover from a draw 
		if (rollover_id != 0) {
			require(msg.sender == games[rollover_id].player1 || msg.sender == games[rollover_id].player2 && 
					player2 == games[rollover_id].player2 || player2 == games[rollover_id].player1); 

			pot_size += games[rollover_id].rollover_pot; 
		}	

        update_game(global_id, msg.sender, player2, pot_size);
		

        //assign the move to the game id 
		games[global_id].player1_move = hashed_move; 

        //start timer after we check if ether sent, if challenged player does not accept then we send the ether back to the player 
        games[global_id].timer = block.timestamp;
		in_game[msg.sender] = true; 
    }

    function accept(uint game_id, string memory move) external {
        require(balances[msg.sender] >= min_bet, "not enough ether to enter the game");
        require(msg.sender != games[game_id].player1, "can't play against yourself dummy"); 
		require(msg.sender == games[game_id].player2, "not the correct player2"); 

        check_timer(game_id); //check to see that the timer is not over the 48 hour mark  
        require(games[game_id].is_active == true, "game is no longer active");
		
		//player 2's move does not need to be secret since they are going second 
		games[game_id].player2_move = move;
		games[game_id].accepted = true; 	
		games[game_id].pot += min_bet; //update by 1 ether  
		in_game[msg.sender] = true; 
    }

	function eval_winner(uint game_id, string memory move, uint64 secret_key) external {
		require(games[game_id].accepted == true);	
		require(msg.sender == games[game_id].player1, "only player 1 can reveal the outcome"); 
		require( 
				keccak256(abi.encodePacked(move, secret_key)) == games[game_id].player1_move,
				"reveal not equal to commit"
			   ); 

			   address player1 = games[game_id].player1;
			   address player2 = games[game_id].player2;

			   bytes memory eval = bytes.concat(bytes(move), bytes(games[game_id].player2_move));

			  address winner;
				
			  //check the encoded bytes to see who won 
			  if(keccak256(eval) == keccak256(bytes("rockrock")) || 
				keccak256(eval) == keccak256(bytes("paperpaper")) || 
				keccak256(eval) == keccak256(bytes("scissorsscissors"))) {

					winner = address(0);

					//half of pot rolls over, half is left to send back to p1 and p2 
					uint half = (games[game_id].pot * 50) / 100;
					//update by half of pot in case there is more than one rollover pot 
					games[game_id].pot = half; 
					balances[player1] -= (half * 50) / 100; 
					balances[player2] -= (half * 50) / 100; 

					games[game_id].rollover_pot = half; 

			  } else if 
				(keccak256(eval) == keccak256(bytes("rockscissors")) || 
			 	keccak256(eval) == keccak256(bytes("scissorspaper")) || 
				keccak256(eval) == keccak256(bytes("paperrock"))) {

					winner = player1;  
					balances[player1] += games[game_id].pot; 
					balances[player2] -= 1 ether; 


			  } else if 
				(keccak256(eval) == keccak256(bytes("paperscissors")) || 
			 	keccak256(eval) == keccak256(bytes("rockpaper")) || 
				keccak256(eval) == keccak256(bytes("scissorsrock"))) {

					winner = player2;  
					balances[player2] += games[game_id].pot; 
					balances[player1] -= 1 ether; 

				}
				
				//final game update that closes out the game
				games[game_id].winner = winner; 
				games[game_id].is_active = false; 
				in_game[player1] = false; 
				in_game[player2] = false; 
	}

    //update struct in another func 
    function update_game(uint game_id,
                         address p1,
                         address p2,
                         uint pot_size) internal {

                        games[game_id].local_id = game_id;
                        games[game_id].is_active = true;
                        games[game_id].player1 = p1;
                        games[game_id].player2 = p2;
                        games[game_id].pot += pot_size;
    }

    function check_timer(uint game_id) public returns(uint time_remaining) {

        uint start_time = games[game_id].timer;
        uint end_time = start_time + 48 hours;
        if (block.timestamp > end_time) {
            time_remaining = 0;
            games[game_id].is_active = false;
			games[game_id].winner = address(this); //just set to anything other than p1, p2, or 0 address so p1 can withdraw 
        } else {
            time_remaining =  end_time - block.timestamp;
        }

        return time_remaining;
    }

    receive() external payable {}

    fallback() external payable {}



}

