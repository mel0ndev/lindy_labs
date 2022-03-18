const Web3 = require('web3'); 
const web3 = new Web3('http://127.0.0.1:8545');

const test_address = "0x2C25606A8423C7B82b5bec3d04CF12f6774c2468"; 
const test_abi = require("../build/contracts/RockPaperScissors.json").abi;


const test = new web3.eth.Contract(
	test_abi, 
	test_address
); 

const eth1 = '1000000000000000000'; 
const max_gas = 6721975; 

async function run() {
	const accounts = await web3.eth.getAccounts(); 
	const player1 = accounts[0]; 
	const player2 = accounts[1];

	console.log(player1, player2); 
	
	await test.methods.deposit().send({from: player1, value: eth1});  
	const player1Balance = await test.methods.balances(player1).call();
	console.log(`player1 balance: ${player1Balance}`); 

	await test.methods.deposit().send({from: player2, value: eth1});  
	const player2Balance = await test.methods.balances(player2).call();
	console.log(`player2 balance: ${player2Balance}`); 

	console.log('----- Both players have deposited -----');

	await test.methods.start_game(player2, "0xd0feaf36a077d2e243c02bf8b2dd1dae2ec92c0a2057df862524ea3596c7ac43" ,0).send({from: player1, gas: max_gas}); 

	const game_id = await test.methods.global_id().call();
	console.log(`global count is ${game_id}`); 

	const game_struct = await test.methods.games(game_id).call(); 
	console.table(game_struct);
	const local_id = game_struct[0]; 

	console.log('----- Waiting for Player 2 -----'); 
		
	const time_left = await test.methods.check_timer(game_id).call();
	console.log(`player2 has ${time_left} blocks left to respond!`); 

	await test.methods.accept(game_id, "scissors").send({from: player2, gas: max_gas}); 
	const updated_game = await test.methods.games(game_id).call(); 
	console.table(updated_game);

	console.log('----- Both Players have gone! -----\n'); 
	console.log('----- Let\'s see who won! -----\n'); 

	await test.methods.eval_winner(game_id, "rock", 777).send({from: player1, gas: max_gas}); 

	const winner = await test.methods.games(game_id).call(); 
	console.log(`congrats: ${winner[10]}!`); 

	console.log('check for updated balances...'); 
	const new_balance_p1 = await test.methods.balances(player1).call(); 
	const new_balance_p2 = await test.methods.balances(player2).call(); 
	console.table([new_balance_p1, new_balance_p2]); 

	console.log('final struct check...');  
	const final_outcome = await test.methods.games(game_id).call(); 
	console.table(final_outcome); 

	console.log('checking withdraw...'); 
	await test.methods.withdraw().send({from: player1, gas: max_gas});  
	console.log('player 1 has withdrawn successfully!'); 

}

run(); 
