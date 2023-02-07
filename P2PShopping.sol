// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract P2PShopping {

    struct Product {
        string id;
        string title;
        string imageUrl;
        uint stock;
        uint price;
        address soldBy;
    }

    Product[] public products;
    address private owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Forbidden");
        _;
    }

    function transferOwnership() public onlyOwner {
        owner = msg.sender;
    }

    function getAllProducts() public view returns(Product[] memory){
        return products;
    }

    function compare(string memory _a, string memory _b) public pure returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }

    function getOneProductById(string memory productId) public view returns(Product memory) {
        for(uint productIndex = 0; productIndex < products.length; productIndex++) {
            Product memory product = products[productIndex];
            if(compare(productId, product.id) == 0) {
                return product;
            }
        }
        Product memory nullProduct;
        return nullProduct;
    }

    function postAProduct(Product calldata newProduct) public {
        products.push(newProduct);
    }

    modifier onlyProductOwner(string memory productId) {
        Product memory foundProduct = getOneProductById(productId);
        require(msg.sender == foundProduct.soldBy, "Only Admins Can Update Product.");
        _;
    }

    function updateAProduct(Product calldata productUpdated) public onlyProductOwner(productUpdated.id) {
        for(uint productIndex = 0; productIndex < products.length; productIndex++) {
            Product storage product = products[productIndex];
            if(compare(product.id, productUpdated.id) == 0) {
                product.title = productUpdated.title;
                product.imageUrl = productUpdated.imageUrl;
                product.stock = productUpdated.stock;
                product.price = productUpdated.price;
            }
        }
    }

    function deleteAProduct(string memory productId) public onlyProductOwner(productId) returns(int) {
        for(uint productIndex = 0; productIndex < products.length; productIndex++) {
            Product memory product = products[productIndex];
            if(compare(product.id, productId) == 0) {
                if (productIndex >= products.length) return (-1);
                for (uint i = productIndex; i < products.length-1; i++){
                    products[i] = products[i+1];
                }
                delete products[products.length-1];
                return (0);
            }
        }
        return (1);
    }

    modifier inStock(string memory productId) {
        Product memory foundProduct = getOneProductById(productId);
        require(foundProduct.stock > 0, "Out Of Stock");
        _;
    }

    modifier hasEnoughMoney(string memory productId) {
        Product memory foundProduct = getOneProductById(productId);
        require(msg.value == foundProduct.price, "Not enough Money.");
        _;
    }

    function buyAProduct(string memory productId) public payable inStock(productId) hasEnoughMoney(productId) {
        for(uint productIndex = 0; productIndex < products.length; productIndex++) {
            Product storage product = products[productIndex];
            if(compare(product.id, productId) == 0) {
                product.stock--;
                address payable recipient = payable(product.soldBy);
                recipient.transfer(msg.value);
            }
        }
    }

}
