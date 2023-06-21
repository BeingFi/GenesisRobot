// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "./ERC721Basic.sol";
import "./WhiteList.sol";

contract GenesisRobot is ERC721Basic, WhiteList, ERC721URIStorageUpgradeable {

  using StringsUpgradeable for uint256;

  // using SafeMath for uint;
  uint16 private constant CONST_STAGE_NONE                   = 0;              // 未开启阶段
  uint16 private constant CONST_STAGE_ONE                    = 1;              // 白名单免费阶段
  uint16 private constant CONST_STAGE_TWO                    = 2;              // 白名单折扣阶段
  uint16 private constant CONST_STAGE_THREE                  = 3;              // 公共发行阶段

  uint16 private constant CONST_FREE_MINT_LIMIT              = 2;              // 免费阶段最多可mint数量
  uint16 private constant CONST_DISCOUNT_LIMIT               = 3;              // 折扣阶段最多可mint数量

  uint16 private constant CONST_STAGE_TWO_MINT_FEE          = 39;             // 折扣阶段收取0.039 ETH
  uint16 private constant CONST_STAGE_THREE_MINT_FEE        = 59;             // 公共发行阶段收取0.059 ETH

  uint16 private constant CONST_ONE_SUPPLY_LIMIT            = 600;            // 第一阶段最多供应量
  uint16 private constant CONST_TWO_SUPPLY_LIMIT            = 1000;           // 第二阶段最多供应量
  uint16 private constant CONST_TOTAL_SUPPLY_LIMIT          = 2048;           // 最多供应量
  uint32 private constant CONST_STAGE_TIME_LIMIT            = (8*3600);       // 每阶段时间 8个小时

  uint256 private constant CONST_DECIMALS_BASE              = 10**18;         // 基础代币ETH精度  
  uint256 private constant CONST_DECIMALS_MINT              = 10**15;         // MINT 收取ETH精度 0.001 ETH 

  string private  constant CONST_ERC721_NAME                = "BeingFi Genesis Robot";
  string private  constant CONST_ERC721_SYMBOL              = "BFGR";
  string private  constant CONST_IPFS_BASE_URI              = "https://ipfs.io/ipfs/QmNMxRDsXkHAbTfdMnmrUig8cTHw38m3cGuFyhKgX4eKjM/";

  error WaitForPublic(); 
  error MintReachingTimeLimit(); 

  uint16 private _maxTotalSupply;                           // 最多供应量
  uint16 private _currentTokenId;                           // 当前mint的id

  uint16 private _stage;                                    // 当前阶段
  uint16 private _stageTwoMintFee;                          // 折扣阶段收取mint费用
  uint16 private _stageThreeMintFee;                        // 发行阶段收取mint费用

  uint32 private _stageTime;                                // 阶段时间
  

  address private _feeReceiveAddress;                        // 保留地址-暂不用

  // Contract-level metadata
  string  private _contractURI;                              // opensea 
  string  private _ipfs_baseURI;                             // opensea 

  function initialize() public initializer {
    // 继承初始化

    __Ownable_init();
    
    // ERC721 标准接口
    __ERC721_init_unchained(CONST_ERC721_NAME, CONST_ERC721_SYMBOL);
    
    // 含版税信息的扩展接口 
        
    // 自定义初始化
    // 默认返回版税信息: 合约自己和5%
      _setDefaultRoyalty( address(this), 500);

      // 初始化参数
      _maxTotalSupply = CONST_TOTAL_SUPPLY_LIMIT;
      _stage = CONST_STAGE_NONE;
      _stageTime = CONST_STAGE_TIME_LIMIT;
      _stageTwoMintFee = CONST_STAGE_TWO_MINT_FEE;
      _stageThreeMintFee = CONST_STAGE_THREE_MINT_FEE;

      _ipfs_baseURI = CONST_IPFS_BASE_URI;

      setAdmin(_msgSender());
      updateVersion(10000);
  }

  /////////////////////////////////////////////////////////////////////////////////////
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {        
        // If there is no base URI, return the token URI.
        if (bytes(_ipfs_baseURI).length == 0) {
            return super.tokenURI(tokenId);
        }

        return string(abi.encodePacked(_ipfs_baseURI, (tokenId+1).toString(), ".json"));
  }

  function contractURI() public view returns (string memory) {
    
    // If there is no base URI, return the token URI.
    if (bytes(_contractURI).length == 0) {
        return string(abi.encodePacked(_ipfs_baseURI, "main.json"));
    }

    return _contractURI;
  }

  /////////////////////////////////////////////////////////////////////////////////////
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Basic, ERC721Upgradeable) returns (bool) {
      return super.supportsInterface(interfaceId);
  }

  /////////////////////////////////////////////////////////////////////////////////////
  // 获取参数设置
  function getStage() public view returns (uint16) {
      return _stage;
  }

  function getStageTime() public view returns (uint32) {
      return _stageTime;
  }

  function getStageTwoMintFee() public view returns (uint256) {
      return _stageTwoMintFee * CONST_DECIMALS_MINT;
  }

  function getStageThreeMintFee() public view returns (uint256) {
      return _stageThreeMintFee * CONST_DECIMALS_MINT;
  }

  function getMintFeeBalance() public view returns (uint256) {
      return address(this).balance;
  }

  function totalSupply() public view returns (uint256) {
      return _currentTokenId;
  }

  /////////////////////////////////////////////////////////////////////////////////////
  // 参数设置
  function updateIpfsBaseURI(string memory _ipfsURI) public onlyAdmin returns (bool) {
      _ipfs_baseURI = _ipfsURI;
      return true;
  }

  // 调整阶段时间
  function updateStageTime(uint32 iStageTime) public onlyAdmin returns (bool) {
      _stageTime = iStageTime;
      return true;
  }

  // 调整阶段
  function updateStage(uint16 iStage) public onlyAdmin returns (bool) {
      _stage = iStage;
      return true;
  }

  // 调整折扣阶段价格
  function updateStageTwoMintFee(uint16 iMintFee) public onlyAdmin returns (bool) {
      _stageTwoMintFee = iMintFee;
      return true;
  }

  // 调整公共发行阶段价格
  function updateStageThreeMintFee(uint16 iMintFee) public onlyAdmin returns (bool) {
      _stageThreeMintFee = iMintFee;
      return true;
  }

  // 调整白名单函数:
  // addWhitelist = addMintWhiteList
  // removeWhitelist = removeMintWhiteList

  // 调整元信息
  // updateMetadata = setTokenURI
  function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyAdmin {      
      _setTokenURI(tokenId, _tokenURI);      
  }

  function setContractURI(string memory strURI) public onlyAdmin {
      _contractURI = strURI;
  }

  // 调试用删除用户信息
  // function clearWhiteUser(address _clearedUser) public onlyAdmin {
  //     delete mapWhiteListInfo[_clearedUser];
  // }

  /////////////////////////////////////////////////////////////////////////////////////
  // 用于白名单地址 mint NFT。在合约中需要记录白名单地址，以及每个地址已经 mint 的 NFT 数量，防止超过限制。
  function mintNFT(uint256 _count) public payable returns (uint256) {
      uint16 currentStage = CONST_STAGE_NONE;

      // 判断阶段的时间是否正确
      for(uint16 i = _stage; i < CONST_STAGE_THREE; i++) {
          (bool bFound, uint256 baseTime) = getBaseLockTime(i);
          if( bFound && baseTime > 0 ) {
              if( block.timestamp > baseTime && ( block.timestamp < (baseTime + _stageTime) ) ) {
                  currentStage = i;
                  break;
              }
          } 
      } 
      
      if( currentStage == CONST_STAGE_NONE || _count == 0 ) {
        revert WaitForPublic();
      }
      
      uint16 addCount =  uint16(_count);
      address payable spender = payable(_msgSender());

           
      // 第三阶段前需要判断是否在白名单中
      tagMintInfo memory mintInfo = getMintWhiteListInfo(spender);

      uint256 mintFee = 0;

      if( currentStage < CONST_STAGE_THREE ) {
        if( mintInfo.isInMintWhite != true ) {
          revert WaitForPublic();
        }
        
        if( currentStage == CONST_STAGE_ONE ) {
            if( mintInfo.freeMintCount + addCount  > CONST_FREE_MINT_LIMIT ) {
              // 第一阶段白名单上限
              revert MintReachingTimeLimit();
            }

            if( _currentTokenId + addCount > CONST_ONE_SUPPLY_LIMIT ) {
              // 第一阶段总量上限
              revert MintReachingTimeLimit();
            }

            mapWhiteListInfo[spender].freeMintCount += addCount;
        } else if( currentStage == CONST_STAGE_TWO ) {
            if( mintInfo.discountMintCount + addCount > CONST_DISCOUNT_LIMIT ) {
              // 第二阶段白名单上限
              revert MintReachingTimeLimit();
            }

            if( _currentTokenId + addCount > CONST_TWO_SUPPLY_LIMIT ) {
              // 第二阶段总量上限
              revert MintReachingTimeLimit();
            }

            mapWhiteListInfo[spender].discountMintCount += addCount;
            // 折扣费用
            mintFee = (CONST_DECIMALS_MINT * _stageTwoMintFee * addCount);
        }                              
      } else {
        // 扣除mint费用
        mintFee = (CONST_DECIMALS_MINT * _stageThreeMintFee * addCount);
      }

      // 收取mint费用
      if( mintFee > 0 ) {   
        // 直接检查mint的携带基础币   
        if( msg.value < mintFee ) {
          revert NotEnoughBalance();
        }
      }    

      // 如果在黑名单中
      if( mintInfo.isInBlack ) {
        revert MintReachingTimeLimit();
      }

      // 获取数量作为ID 
      if( _currentTokenId + addCount > _maxTotalSupply ) {
        revert MintReachingTimeLimit();
      }

      for(uint16 i = 0; i < addCount; i++) {
          _safeMint(spender, _currentTokenId);
          _currentTokenId++;
      } 

      if( _stage != currentStage) {
        // 自动调整阶段值
        _stage =  currentStage; 
      }
            
      return (_currentTokenId-1);
  }

  // transferNFT = safeTransferFrom
}
