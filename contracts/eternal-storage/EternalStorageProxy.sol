pragma solidity ^0.4.18;

import "./EternalStorage.sol";
import "./IEternalStorageProxy.sol";


/**
 * @title EternalStorageProxy
 * @dev This proxy holds the storage of the token contract and delegates every call to the current implementation set.
 * Besides, it allows to upgrade the token's behaviour towards further implementations, and provides
 * authorization control functionalities
 */
contract EternalStorageProxy is EternalStorage, IEternalStorageProxy {

    /**
    * @dev This event will be emitted every time the implementation gets upgraded
    * @param version representing the version number of the upgraded implementation
    * @param implementation representing the address of the upgraded implementation
    */
    event Upgraded(uint256 version, address indexed implementation);

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyProxyStorage() {
        require(msg.sender == getProxyStorage());
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == getOwner());
        _;
    }

    function getProxyStorage() public view returns(address) {
        return addressStorage[keccak256("proxyStorage")];
    }

    function getOwner() public view returns(address) {
        return addressStorage[keccak256("owner")];
    }

    function EternalStorageProxy(address _proxyStorage, address _implementationAddress) public {
        require(_implementationAddress != address(0));

        if (_proxyStorage != address(0)) {
            _setProxyStorage(_proxyStorage);
        } else {
            _setProxyStorage(address(this));
        }
        
        _implementation = _implementationAddress;
        _setOwner(msg.sender);
    }

    /**
    * @dev Fallback function allowing to perform a delegatecall to the given implementation.
    * This function will return whatever the implementation call returns
    */
    function () public payable {
        address _impl = _implementation;
        require(_impl != address(0));

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    /**
     * @dev Allows ProxyStorage contract to upgrade the current implementation.
     * @param implementation representing the address of the new implementation to be set.
     */
    function upgradeTo(address implementation) public onlyProxyStorage {
        require(_implementation != implementation);
        require(implementation != address(0));

        uint256 _newVersion = _version + 1;
        assert(_newVersion > _version);
        _version = _newVersion;

        _implementation = implementation;
        Upgraded(_version, _implementation);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a _newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        OwnershipTransferred(getOwner(), _newOwner);
        _setOwner(_newOwner);
    }

    /**
     * @dev Allows the current owner to relinquish ownership.
     */
    function renounceOwnership() public onlyOwner {
        OwnershipRenounced(getOwner());
        _setOwner(address(0));
    }

    function _setProxyStorage(address _proxyStorage) private {
        addressStorage[keccak256("proxyStorage")] = _proxyStorage;
    }

    function _setOwner(address _owner) private {
        addressStorage[keccak256("owner")] = _owner;
    }

}