// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PersonalVault {
    address public owner;           // Siapa pemilik vault ini
    uint256 public unlockTime;      // Kapan dana bisa diambil
    
    // Events sesuai spesifikasi brief
    event Deposit(address indexed sender, uint256 amount);
    event Withdrawal(uint256 amount, uint256 timestamp);
    event LockExtended(uint256 newUnlockTime);
    
    // Custom errors untuk efisiensi gas
    error FundsLocked();
    error NotOwner();
    error InvalidUnlockTime();

    // Constructor bawaan wajib
    constructor(uint256 _unlockTime) payable {
        require(_unlockTime > block.timestamp, "Unlock time must be in the future");
        owner = msg.sender;
        unlockTime = _unlockTime;
    }

    // Access Control Pattern menggunakan Custom Error
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // 1. Fungsi Deposit untuk menerima ETH
    function deposit() public payable {
        emit Deposit(msg.sender, msg.value);
    }

    // 2. Fungsi Withdraw untuk menarik seluruh dana setelah masa kunci lewat
    function withdraw() public onlyOwner {
        // Cek apakah waktu kunci sudah terlewati
        if (block.timestamp < unlockTime) {
            revert FundsLocked();
        }
        
        uint256 amount = address(this).balance;
        require(amount > 0, "No balance to withdraw");

        // Menggunakan call{value: amount}("") sesuai Security Requirements
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawal(amount, block.timestamp);
    }

    // 3. Fungsi Extend Lock untuk memperpanjang waktu penguncian
    function extendLock(uint256 newTime) public onlyOwner {
        // Validasi agar waktu baru tidak boleh lebih pendek atau sama dengan waktu sekarang
        if (newTime <= unlockTime) {
            revert InvalidUnlockTime();
        }
        
        unlockTime = newTime;
        emit LockExtended(newTime);
    }
}
