truffle-flattener contracts/$1.sol > flattened.sol
sed -e 's/\/\/ SPDX-License-Identifier:.*//g' -i flattened.sol 
