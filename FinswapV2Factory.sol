// SPDX-License-Identifier: MIT

pragma solidity =0.5.16;

import './FinswapV2Pair.sol';
import '../interfaces/IFinswapV2Factory.sol';

contract FinswapV2Factory is IFinswapV2Factory {
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(FinswapV2Pair).creationCode));

    address public feeTo;
    address public feeToSetter;
    bool public locked;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter, bool _locked) public {
        feeToSetter = _feeToSetter;
        locked = _locked;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'Finswap: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Finswap: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'Finswap: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(FinswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IFinswapV2Pair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'Finswap: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'Finswap: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

    function setLocked(bool _locked) external {
        require(msg.sender == feeToSetter, 'Finswap: FORBIDDEN');
        locked = _locked;
    }
}