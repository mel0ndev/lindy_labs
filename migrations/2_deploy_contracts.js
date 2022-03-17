const RockPaperScissors = artifacts.require("RockPaperScissors"); 


module.exports = async function(deployer) {

    await deployer.deploy(RockPaperScissors);

}

