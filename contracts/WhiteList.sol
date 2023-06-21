// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";

// import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
// import "./ERC721Upgradeable.sol";
import "./SecurityOwner.sol";

contract WhiteList is SecurityOwner {

    // Add the library methods
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.UintToUintMap;

    // 动态基准时间类型
    EnumerableMapUpgradeable.UintToUintMap  private baseLockTime;

    // 查询动态基准时间
    function getBaseLockTime(uint256 lockIndex) public view returns (bool, uint256) {
        return baseLockTime.tryGet(lockIndex);
    }

    // 设置动态基准时间
    function setBaseLockTime(uint256 lockIndex, uint256 lockValue) public onlyAdmin returns (bool) {
        return baseLockTime.set(lockIndex, lockValue);
    }

    // 删除动态基准时间
    // function removeBaseLockTime(uint256 lockIndex) public onlyOwner returns (bool) {
    //     return baseLockTime.remove(lockIndex);
    // }

    /////////////////////////////////////////////////////////////////////////////
    struct tagMintInfo {
        // 免费mint次数
        uint16 freeMintCount;                  
        // 折扣mint次数
        uint16 discountMintCount;
        // 标记开启白名单状态
        bool isInMintWhite;
        bool isInBlack;
    }

    // mint白名单
    mapping (address => tagMintInfo) internal mapWhiteListInfo;

    //  查询白名单状态
    function getMintWhiteListInfo(address _maker) public view returns (tagMintInfo memory) {
        return mapWhiteListInfo[_maker];
    }
    
    function addMintWhiteList (address _mintUser) public onlyAdmin {
        mapWhiteListInfo[_mintUser].isInMintWhite = true;
        emit AddedMintWhiteList(_mintUser);
    }

    function removeMintWhiteList (address _clearedUser) public onlyAdmin {
        mapWhiteListInfo[_clearedUser].isInMintWhite = false;
        emit RemovedMintWhiteList(_clearedUser);
    }

    event AddedMintWhiteList(address _user);

    event RemovedMintWhiteList(address _user);
    
    function addBlackList (address _evilUser) public onlyAdmin {
        mapWhiteListInfo[_evilUser].isInBlack = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public onlyAdmin {
        mapWhiteListInfo[_clearedUser].isInBlack = false;
        emit RemovedBlackList(_clearedUser);
    }

    event AddedBlackList(address _user);

    event RemovedBlackList(address _user);
    
}