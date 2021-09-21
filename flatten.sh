truffle-flattener contracts/*.sol > flattened.sol
sed -e 's/\/\/ SPDX-License-Identifier:.*//g' -i flattened.sol 
