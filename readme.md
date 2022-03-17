# Lindy Labs RPS Game 

### To Run the Tests

I am sorry, first of all, I only found out about how great foundry was during the 
writing of these contracts, but I was not comforable enough to use it without 
spending too much time on this, so I figured I would just stick to the usual method
of testing contracts that I use, which is, uh, not great? 

The tests are written in js and use the web3 library which, I understand it not ideal, 
however when I originally started testing like this I wanted to familiarize myself 
with the library, and I've gotten used to it, so I figured I would just use it here. 

To run the tests run ```npm install``` 

ensure that truffle and web3 are installed. 

then deploy the contract with ```truffle migrate --reset``` 

then simply run the tests with ```node ${test_file_name}``` and view the output in 
your terminal. 

If you want to change the variables or anything in the contract, those
will have to be done manually in the test files themselves. 
