// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import "../lib/openzeppelin-contracts/contracts/interfaces/IERC2981.sol";
import "../lib/chainlink-brownie-contracts/contracts/src/v0.8/VRFConsumerBase.sol";

contract CharacterNFT is ERC721Enumerable, ERC721URIStorage, Ownable, IERC2981, VRFConsumerBase {
    struct Character {
        uint256 health;
        uint256 mana;
        uint256 str;
        uint256 dex;
        uint256 luk;
        uint256 intelligence;
        uint256 armor;
        uint256 magicArmor;
        uint256 avoidability;
    }

    struct RoyaltyInfo {
        address recipient;
        uint24 amount; // 百分率の100倍（例：10% = 1000）
    }

    bytes32 internal keyHash;
    uint256 internal fee;
    mapping(bytes32 => address) public requestIdToSender;
    mapping(uint256 => Character) public tokenIdToCharacter;
    mapping(uint256 => RoyaltyInfo) private _royalties;

    constructor(
        address _VRFCoordinator,
        address _LinkToken,
        bytes32 _keyHash,
        uint256 _fee
    ) ERC721("CharacterNFT", "CHNFT") VRFConsumerBase(_VRFCoordinator, _LinkToken) {
        keyHash = _keyHash;
        fee = _fee;
    }

    function mint(
        address to,
        uint256 tokenId,
        string memory tokenURI,
        address royaltyRecipient,
        uint24 royaltyValue
    ) public onlyOwner {
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        _setTokenRoyalty(tokenId, royaltyRecipient, royaltyValue);
    }

    function createCharacter() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        requestId = requestRandomness(keyHash, fee);
        requestIdToSender[requestId] = msg.sender;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        address owner = requestIdToSender[requestId];
        uint256 newItemId = totalSupply();

        // Generate random stats
        uint256 health = (randomness % 26) + 30; // 30~55
        uint256 mana = ((randomness >> 1) % 71); // 0~70
        uint256 str = ((randomness >> 2) % 10) + 14; // 14~23
        uint256 dex = ((randomness >> 3) % 10) + 14; // 14~23
        uint256 luk = ((randomness >> 4) % 10) + 14; // 14~23
        uint256 intelligence = ((randomness >> 5) % 10) + 14; // 14~23
        uint256 armor = ((randomness >> 6) % 11); // 0~10
        uint256 magicArmor = ((randomness >> 7) % 11); // 0~10
        uint256 avoidability = ((randomness >> 8) % 9); // 0~8

        Character memory newCharacter = Character({
            health: health,
            mana: mana,
            str: str,
            dex: dex,
            luk: luk,
            intelligence: intelligence,
            armor: armor,
            magicArmor: magicArmor,
            avoidability: avoidability
        });

        tokenIdToCharacter[newItemId] = newCharacter;
        _safeMint(owner, newItemId);
    }

    function _setTokenRoyalty(uint256 tokenId, address recipient, uint24 value) internal {
        require(value <= 10000, "ERC2981: Royalty value should be <= 10000");
        _royalties[tokenId] = RoyaltyInfo(recipient, value);
    }

    // ERC2981標準のroyaltyInfo関数の実装
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address, uint256) {
        RoyaltyInfo memory royalties = _royalties[tokenId];
        uint256 royaltyAmount = (salePrice * royalties.amount) / 10000;
        return (royalties.recipient, royaltyAmount);
    }

    // ERC165標準のsupportsInterface関数のオーバーライド
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    // 以下、オーバーライドが必要な関数
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721Enumerable, ERC721) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721URIStorage, ERC721) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721URIStorage, ERC721) returns (string memory) {
        return super.tokenURI(tokenId);
    }
}
