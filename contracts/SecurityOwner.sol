// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

// import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract SecurityOwner is OwnableUpgradeable {

    error Unauthorized();
    error UseZeroAddress();
    error SecurityCheckFailed();
    error SecurityCheckCodeFailed();
    error SecurityTransferFailed();
    error TransferToSelf();
    error NotEnoughBalance();
    error AddressNotContract();

    // ContextUpgradeable
    uint32      private             _verSion;       // 当前版本号
    uint256     private             _securityCode;  // 转移所有权密码
    address     private             _admin;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAdmin() {
        _checkAdmin();
        _;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkAdmin() internal view virtual {
        if( _admin != _msgSender() ) {
            revert Unauthorized();
        }
    }  

    function setAdmin(address newAdmin) public virtual onlyOwner {
        if( newAdmin == address(0) ) {
            revert UseZeroAddress();
        }
        
        _admin = newAdmin;
    }  

    // function __SecurityOwner_init() internal onlyInitializing {
    //     __Ownable_init();
    //     setAdmin(_msgSender());
    //     _verSion = 100000;
    // }

    function getVersion() public view returns (uint32) {
        return _verSion;
    }

    function updateVersion(uint32 iVersion) public onlyAdmin returns (bool) {
        _verSion = iVersion;
        return true;
    } 

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function getSecurityCode(string memory strCode) public view onlyOwner returns (uint256) {
        // return uint256(keccak256( string.concat(bytes(strCode), bytes("@BGTToken")) ));
        return uint256(keccak256( bytes(string.concat(strCode, "@BGTToken")) ));
    }

    function dumpSecurityCode() public view onlyOwner returns (uint256) {
        return _securityCode;
    }

    function setSecurityCode(string memory strOldCode, string memory strNewCode) public onlyOwner returns (bool) {
        uint256 checkCode = getSecurityCode(strOldCode);
        if( _securityCode == 0 || _securityCode == checkCode ) {
            checkCode = getSecurityCode(strNewCode);
            if( _securityCode != checkCode) {
                _securityCode = checkCode;
                return true;
            }
        }

        revert SecurityCheckCodeFailed();
    }

    // 重载接口，需要配合创建时候的Key才能修改拥有者
    function transferOwnership(address newOwner) public override virtual onlyOwner  {
        if(_securityCode == 0) {
            _transferOwnership(newOwner);
        } else {
            revert SecurityCheckFailed();
        }
    }

    function securityTransferOwnership(address newOwner, string memory strCode) public virtual onlyOwner returns (bool)  {
        uint256 checkCode = getSecurityCode(strCode);
        if(_securityCode == 0 || _securityCode == checkCode) {

            if( newOwner == address(0) ) {
                revert UseZeroAddress();
            }

            if( owner() != newOwner ) {
                _transferOwnership(newOwner);
                return true;
            }
            
            revert SecurityTransferFailed();
        } else {
            revert SecurityCheckCodeFailed();
        }
    }   

    // 从合约账户提取代币
    function transferOut(IERC20Upgradeable sourceToken, address payable receiver, uint256 amount) public onlyOwner returns (bool) {
        address sender = address(this);
        
        if( receiver == sender ) {
            revert TransferToSelf();
        }
        
        if( address(sourceToken) == address(0) ) {
            if( sender.balance < amount ) {
                revert NotEnoughBalance();
            }
            
            receiver.transfer(amount);
        } else {
            uint256 senderBalance = sourceToken.balanceOf(sender);
            if( senderBalance < amount ) {
                revert NotEnoughBalance();
            }

            sourceToken.transfer(receiver, amount);
        }
        
        return true;
    } 

    // 从合约账户提取NFT
    function transferNFTOut(IERC721Upgradeable sourceToken, address payable receiver, uint256 tokenId) public onlyOwner returns (bool) {
        address sender = address(this);
        
        if( receiver == sender ) {
            revert TransferToSelf();
        }
        
        
        if( !AddressUpgradeable.isContract(address(sourceToken)) ) {
            revert AddressNotContract();
        }

        if( address(sourceToken) == address(0) ) {
            revert UseZeroAddress();
        } else {
            sourceToken.transferFrom(sender, receiver, tokenId);
        }
        
        return true;
    }
}