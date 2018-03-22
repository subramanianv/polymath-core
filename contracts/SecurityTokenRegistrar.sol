pragma solidity ^0.4.18;

import './interfaces/ITickerRegistrar.sol';
import './tokens/SecurityToken.sol';
import './interfaces/ISTProxy.sol';
import './interfaces/ISecurityTokenRegistrar.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

contract SecurityTokenRegistrar is Ownable, ISecurityTokenRegistrar {

    address public transferManagerFactory;
    address public permissionManagerFactory;

    //Shoud be set to false when we have more TransferManager options
    bool addTransferManager = true;
    bool addPermissionManager = true;

    event LogNewSecurityToken(string _ticker, address _securityTokenAddress, address _owner);

     /**
     * @dev Constructor use to set the essentials addresses to facilitate
     * the creation of the security token
     */
    function SecurityTokenRegistrar(address _polyAddress, address _moduleRegistry, address _tickerRegistrar, address _transferManagerFactory, address _permissionManagerFactory, address _STVersionProxy) public {
        polyAddress = _polyAddress;
        moduleRegistry = _moduleRegistry;
        tickerRegistrar = _tickerRegistrar;
        transferManagerFactory = _transferManagerFactory;
        permissionManagerFactory = _permissionManagerFactory;

        setProtocolVersion(_STVersionProxy,"0.0.1");
    }

    /**
     * @dev Creates a new Security Token and saves it to the registry
     * @param _name Name of the security token
     * @param _symbol Ticker symbol of the security token
     * @param _decimals Decimals value for token
     * @param _tokenDetails off-chain details of the token
     */
    function generateSecurityToken(string _name, string _symbol, uint8 _decimals, bytes32 _tokenDetails) public {
        require(bytes(_name).length > 0 && bytes(_symbol).length > 0);
        ITickerRegistrar(tickerRegistrar).checkValidity(_symbol, msg.sender);

        address newSecurityTokenAddress = ISTProxy(protocolVersionST[protocolVersion]).deployToken(
          _name,
          _symbol,
          _decimals,
          _tokenDetails
        );
        if (addPermissionManager) {
          SecurityToken(newSecurityTokenAddress).addModule(permissionManagerFactory, "", 0, true);
        }
        if (addTransferManager) {
          SecurityToken(newSecurityTokenAddress).addModule(transferManagerFactory, "", 0, true);
        }
        SecurityToken(newSecurityTokenAddress).transferOwnership(msg.sender);
        securityTokens[newSecurityTokenAddress] = SecurityTokenData(_symbol, msg.sender, _tokenDetails);
        symbols[_symbol] = newSecurityTokenAddress;
        LogNewSecurityToken(_symbol, newSecurityTokenAddress, msg.sender);
    }

    function setProtocolVersion(address _stVersionProxyAddress, bytes32 _version) public onlyOwner {
      protocolVersion = _version;
      protocolVersionST[_version]=_stVersionProxyAddress;
    }

    function changeAutoSelectionModule(bool _transferManager, bool _permissionManager) public onlyOwner {
      addTransferManager = _transferManager;
      addPermissionManager = _permissionManager;
    }

    //////////////////////////////
    ///////// Get Functions
    //////////////////////////////
    /**
     * @dev Get security token address by ticker name
     * @param _symbol Symbol of the Scurity token
     * @return address _symbol
     */
    function getSecurityTokenAddress(string _symbol) public view returns (address) {
      return symbols[_symbol];
    }
}
