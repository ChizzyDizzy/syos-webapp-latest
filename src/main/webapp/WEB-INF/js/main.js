// ===== SYOS POS System - Main JavaScript File =====

// API Base URL
const API_BASE_URL = '/api';

// Current sale cart (for sales module)
let currentSaleCart = [];

// ===== Initialize Dashboard =====
function initializeDashboard() {
    // Check authentication
    const authToken = sessionStorage.getItem('authToken');
    if (!authToken) {
        window.location.href = '../../index.html';
        return;
    }

    // Set up navigation
    setupNavigation();

    // Update current time
    updateCurrentTime();
    setInterval(updateCurrentTime, 1000);

    // Load initial data
    loadOverviewData();

    // Set up logout button
    const logoutBtn = document.getElementById('logout-btn');
    if (logoutBtn) {
        logoutBtn.addEventListener('click', handleLogout);
    }
}

// ===== Navigation =====
function setupNavigation() {
    const navLinks = document.querySelectorAll('.nav-link');
    
    navLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            
            // Remove active class from all links
            navLinks.forEach(l => l.classList.remove('active'));
            
            // Add active class to clicked link
            this.classList.add('active');
            
            // Get section name
            const sectionName = this.dataset.section;
            
            // Show corresponding section
            showSection(sectionName);
        });
    });
}

function navigateToSection(sectionName) {
    // Update active nav link
    const navLinks = document.querySelectorAll('.nav-link');
    navLinks.forEach(link => {
        if (link.dataset.section === sectionName) {
            link.classList.add('active');
        } else {
            link.classList.remove('active');
        }
    });
    
    // Show section
    showSection(sectionName);
}

function showSection(sectionName) {
    // Hide all sections
    const sections = document.querySelectorAll('.content-section');
    sections.forEach(section => section.classList.remove('active'));
    
    // Show selected section
    const selectedSection = document.getElementById(`${sectionName}-section`);
    if (selectedSection) {
        selectedSection.classList.add('active');
    }
    
    // Update section title
    const titleMap = {
        'overview': 'Dashboard Overview',
        'sales': 'Sales Management',
        'inventory': 'Inventory Management',
        'reports': 'Reports',
        'users': 'User Management'
    };
    
    document.getElementById('section-title').textContent = titleMap[sectionName] || 'Dashboard';
    
    // Load section-specific data
    switch(sectionName) {
        case 'overview':
            loadOverviewData();
            break;
        case 'sales':
            loadSalesData();
            break;
        case 'inventory':
            loadInventoryData();
            break;
        case 'reports':
            // Reports are generated on demand
            break;
        case 'users':
            loadUsersData();
            break;
    }
}

// ===== Utility Functions =====
function updateCurrentTime() {
    const timeElement = document.getElementById('current-time');
    if (timeElement) {
        const now = new Date();
        timeElement.textContent = now.toLocaleString('en-US', {
            weekday: 'long',
            year: 'numeric',
            month: 'long',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    }
}

function showAlert(type, message, duration = 5000) {
    const alertDiv = document.createElement('div');
    alertDiv.className = `alert alert-${type}`;
    alertDiv.textContent = message;
    
    // Insert at top of content body
    const contentBody = document.querySelector('.content-body');
    contentBody.insertBefore(alertDiv, contentBody.firstChild);
    
    // Auto-remove
    setTimeout(() => {
        alertDiv.remove();
    }, duration);
}

// ===== API Functions =====
async function apiRequest(endpoint, options = {}) {
    const authToken = sessionStorage.getItem('authToken');
    
    const defaultOptions = {
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${authToken}`
        }
    };
    
    const finalOptions = { ...defaultOptions, ...options };
    
    try {
        const response = await fetch(`${API_BASE_URL}${endpoint}`, finalOptions);
        const data = await response.json();
        
        if (!response.ok) {
            throw new Error(data.message || 'API request failed');
        }
        
        return data;
    } catch (error) {
        console.error('API Error:', error);
        throw error;
    }
}

// ===== Overview Section =====
async function loadOverviewData() {
    try {
        // Load today's sales
        const todayBills = await apiRequest('/sales/today');
        if (todayBills.success && todayBills.data) {
            const totalSales = todayBills.data.reduce((sum, bill) => sum + bill.totalAmount, 0);
            document.getElementById('today-sales').textContent = `$${totalSales.toFixed(2)}`;
            document.getElementById('today-bills').textContent = todayBills.data.length;
        }
        
        // Load inventory statistics
        const stats = await apiRequest('/inventory/statistics');
        if (stats.success && stats.data) {
            document.getElementById('low-stock-count').textContent = stats.data.lowStockCount;
            document.getElementById('expiring-count').textContent = stats.data.expiringCount;
        }
    } catch (error) {
        console.error('Failed to load overview data:', error);
    }
}

// ===== Sales Section =====
async function loadSalesData() {
    await loadAvailableItems();
    await loadTodaysBills();
}

async function loadAvailableItems() {
    const tbody = document.getElementById('available-items-body');
    tbody.innerHTML = '<tr><td colspan="6">Loading...</td></tr>';
    
    try {
        const response = await apiRequest('/sales/available-items');
        
        if (response.success && response.data) {
            if (response.data.length === 0) {
                tbody.innerHTML = '<tr><td colspan="6" class="text-center">No items available for sale</td></tr>';
                return;
            }
            
            tbody.innerHTML = response.data.map(item => `
                <tr>
                    <td>${item.code}</td>
                    <td>${item.name}</td>
                    <td>$${item.price.toFixed(2)}</td>
                    <td>${item.quantity}</td>
                    <td>${item.expiryDate || 'N/A'}</td>
                    <td>
                        <button class="btn btn-primary" onclick="addToCart('${item.code}', '${item.name}', ${item.price})">
                            Add to Cart
                        </button>
                    </td>
                </tr>
            `).join('');
        }
    } catch (error) {
        tbody.innerHTML = `<tr><td colspan="6" class="text-center">Error loading items: ${error.message}</td></tr>`;
    }
}

async function loadTodaysBills() {
    const tbody = document.getElementById('today-bills-body');
    tbody.innerHTML = '<tr><td colspan="7">Loading...</td></tr>';
    
    try {
        const response = await apiRequest('/sales/today');
        
        if (response.success && response.data) {
            if (response.data.length === 0) {
                tbody.innerHTML = '<tr><td colspan="7" class="text-center">No bills for today</td></tr>';
                return;
            }
            
            tbody.innerHTML = response.data.map(bill => `
                <tr>
                    <td>${bill.billNumber}</td>
                    <td>${new Date(bill.billDate).toLocaleString()}</td>
                    <td>$${bill.totalAmount.toFixed(2)}</td>
                    <td>$${bill.cashTendered.toFixed(2)}</td>
                    <td>$${bill.change.toFixed(2)}</td>
                    <td><span class="badge badge-${bill.transactionType === 'ONLINE' ? 'info' : 'success'}">${bill.transactionType}</span></td>
                    <td>
                        <button class="btn btn-secondary" onclick="viewBillDetails(${bill.billNumber})">
                            View
                        </button>
                    </td>
                </tr>
            `).join('');
        }
    } catch (error) {
        tbody.innerHTML = `<tr><td colspan="7" class="text-center">Error loading bills: ${error.message}</td></tr>`;
    }
}

function addToCart(itemCode, itemName, price) {
    const quantityInput = prompt(`How many units of ${itemName}?`, '1');
    if (quantityInput === null) return;
    
    const quantity = parseInt(quantityInput);
    if (isNaN(quantity) || quantity <= 0) {
        showAlert('error', 'Invalid quantity');
        return;
    }
    
    // Check if item already in cart
    const existingItem = currentSaleCart.find(item => item.itemCode === itemCode);
    if (existingItem) {
        existingItem.quantity += quantity;
    } else {
        currentSaleCart.push({
            itemCode,
            itemName,
            price,
            quantity
        });
    }
    
    showAlert('success', `Added ${quantity} x ${itemName} to cart`);
    showCreateSaleModal();
}

function showCreateSaleModal() {
    if (currentSaleCart.length === 0) {
        showAlert('error', 'Cart is empty. Add items first.');
        return;
    }
    
    const subtotal = currentSaleCart.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    
    const modalHTML = `
        <div class="modal active" id="sale-modal">
            <div class="modal-content">
                <div class="modal-header">
                    <h2>Complete Sale</h2>
                    <button class="modal-close" onclick="closeModal('sale-modal')">&times;</button>
                </div>
                <div class="modal-body">
                    <h3>Cart Items:</h3>
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Item</th>
                                <th>Qty</th>
                                <th>Price</th>
                                <th>Total</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${currentSaleCart.map(item => `
                                <tr>
                                    <td>${item.itemName}</td>
                                    <td>${item.quantity}</td>
                                    <td>$${item.price.toFixed(2)}</td>
                                    <td>$${(item.price * item.quantity).toFixed(2)}</td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                    
                    <div style="margin-top: 20px;">
                        <p><strong>Subtotal: $${subtotal.toFixed(2)}</strong></p>
                    </div>
                    
                    <div class="form-group">
                        <label for="discount">Discount ($)</label>
                        <input type="number" id="discount" class="form-control" value="0" min="0" step="0.01">
                    </div>
                    
                    <div class="form-group">
                        <label for="cash-tendered">Cash Tendered ($)</label>
                        <input type="number" id="cash-tendered" class="form-control" value="${subtotal.toFixed(2)}" min="0" step="0.01" required>
                    </div>
                    
                    <div class="form-group">
                        <label for="transaction-type">Transaction Type</label>
                        <select id="transaction-type" class="form-control">
                            <option value="IN_STORE">In Store</option>
                            <option value="ONLINE">Online</option>
                        </select>
                    </div>
                </div>
                <div class="modal-footer">
                    <button class="btn btn-secondary" onclick="clearCart()">Clear Cart</button>
                    <button class="btn btn-primary" onclick="completeSale()">Complete Sale</button>
                </div>
            </div>
        </div>
    `;
    
    document.getElementById('modal-container').innerHTML = modalHTML;
}

async function completeSale() {
    const discount = parseFloat(document.getElementById('discount').value) || 0;
    const cashTendered = parseFloat(document.getElementById('cash-tendered').value);
    const transactionType = document.getElementById('transaction-type').value;
    
    if (isNaN(cashTendered) || cashTendered <= 0) {
        showAlert('error', 'Invalid cash amount');
        return;
    }
    
    const saleData = {
        items: currentSaleCart.map(item => ({
            itemCode: item.itemCode,
            quantity: item.quantity
        })),
        cashTendered,
        discount,
        transactionType
    };
    
    try {
        const response = await apiRequest('/sales/create', {
            method: 'POST',
            body: JSON.stringify(saleData)
        });
        
        if (response.success) {
            showAlert('success', `Sale completed! Bill #${response.data.billNumber}`);
            clearCart();
            closeModal('sale-modal');
            loadSalesData();
            loadOverviewData();
        }
    } catch (error) {
        showAlert('error', `Failed to complete sale: ${error.message}`);
    }
}

function clearCart() {
    currentSaleCart = [];
    closeModal('sale-modal');
    showAlert('info', 'Cart cleared');
}

async function viewBillDetails(billNumber) {
    try {
        const response = await apiRequest(`/sales/${billNumber}`);
        
        if (response.success && response.data) {
            const bill = response.data;
            
            const modalHTML = `
                <div class="modal active" id="bill-details-modal">
                    <div class="modal-content">
                        <div class="modal-header">
                            <h2>Bill #${bill.billNumber}</h2>
                            <button class="modal-close" onclick="closeModal('bill-details-modal')">&times;</button>
                        </div>
                        <div class="modal-body">
                            <p><strong>Date:</strong> ${new Date(bill.billDate).toLocaleString()}</p>
                            <p><strong>Type:</strong> ${bill.transactionType}</p>
                            
                            <h3>Items:</h3>
                            <table class="data-table">
                                <thead>
                                    <tr>
                                        <th>Item</th>
                                        <th>Qty</th>
                                        <th>Price</th>
                                        <th>Total</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ${bill.items.map(item => `
                                        <tr>
                                            <td>${item.itemName}</td>
                                            <td>${item.quantity}</td>
                                            <td>$${item.unitPrice.toFixed(2)}</td>
                                            <td>$${item.subtotal.toFixed(2)}</td>
                                        </tr>
                                    `).join('')}
                                </tbody>
                            </table>
                            
                            <div style="margin-top: 20px;">
                                <p><strong>Total:</strong> $${bill.totalAmount.toFixed(2)}</p>
                                <p><strong>Discount:</strong> $${bill.discount.toFixed(2)}</p>
                                <p><strong>Cash:</strong> $${bill.cashTendered.toFixed(2)}</p>
                                <p><strong>Change:</strong> $${bill.change.toFixed(2)}</p>
                            </div>
                        </div>
                        <div class="modal-footer">
                            <button class="btn btn-secondary" onclick="closeModal('bill-details-modal')">Close</button>
                        </div>
                    </div>
                </div>
            `;
            
            document.getElementById('modal-container').innerHTML = modalHTML;
        }
    } catch (error) {
        showAlert('error', `Failed to load bill details: ${error.message}`);
    }
}

// ===== Inventory Section =====
async function loadInventoryData() {
    const tbody = document.getElementById('inventory-body');
    tbody.innerHTML = '<tr><td colspan="8">Loading...</td></tr>';
    
    try {
        const response = await apiRequest('/inventory/items');
        
        if (response.success && response.data) {
            if (response.data.length === 0) {
                tbody.innerHTML = '<tr><td colspan="8" class="text-center">No items in inventory</td></tr>';
                return;
            }
            
            tbody.innerHTML = response.data.map(item => {
                const stateBadge = getStateBadge(item.state);
                const expiryInfo = item.expiryDate ? 
                    `<td>${item.expiryDate}</td><td>${item.daysUntilExpiry}</td>` :
                    '<td>N/A</td><td>N/A</td>';
                
                return `
                    <tr>
                        <td>${item.code}</td>
                        <td>${item.name}</td>
                        <td>$${item.price.toFixed(2)}</td>
                        <td>${item.quantity}</td>
                        <td>${stateBadge}</td>
                        ${expiryInfo}
                        <td>
                            <button class="btn btn-secondary" onclick="viewItemDetails('${item.code}')">View</button>
                        </td>
                    </tr>
                `;
            }).join('');
        }
    } catch (error) {
        tbody.innerHTML = `<tr><td colspan="8" class="text-center">Error loading inventory: ${error.message}</td></tr>`;
    }
}

function getStateBadge(state) {
    const badges = {
        'IN_STORE': '<span class="badge badge-info">In Store</span>',
        'ON_SHELF': '<span class="badge badge-success">On Shelf</span>',
        'EXPIRED': '<span class="badge badge-danger">Expired</span>',
        'SOLD_OUT': '<span class="badge badge-warning">Sold Out</span>'
    };
    return badges[state] || '<span class="badge badge-secondary">' + state + '</span>';
}

function showAddStockModal() {
    const modalHTML = `
        <div class="modal active" id="add-stock-modal">
            <div class="modal-content">
                <div class="modal-header">
                    <h2>Add Stock</h2>
                    <button class="modal-close" onclick="closeModal('add-stock-modal')">&times;</button>
                </div>
                <div class="modal-body">
                    <form id="add-stock-form">
                        <div class="form-group">
                            <label for="stock-code">Item Code*</label>
                            <input type="text" id="stock-code" class="form-control" required>
                        </div>
                        <div class="form-group">
                            <label for="stock-name">Item Name*</label>
                            <input type="text" id="stock-name" class="form-control" required>
                        </div>
                        <div class="form-group">
                            <label for="stock-price">Price*</label>
                            <input type="number" id="stock-price" class="form-control" step="0.01" required>
                        </div>
                        <div class="form-group">
                            <label for="stock-quantity">Quantity*</label>
                            <input type="number" id="stock-quantity" class="form-control" required>
                        </div>
                        <div class="form-group">
                            <label for="stock-expiry">Expiry Date</label>
                            <input type="date" id="stock-expiry" class="form-control">
                        </div>
                    </form>
                </div>
                <div class="modal-footer">
                    <button class="btn btn-secondary" onclick="closeModal('add-stock-modal')">Cancel</button>
                    <button class="btn btn-primary" onclick="submitAddStock()">Add Stock</button>
                </div>
            </div>
        </div>
    `;
    
    document.getElementById('modal-container').innerHTML = modalHTML;
}

async function submitAddStock() {
    const stockData = {
        code: document.getElementById('stock-code').value.toUpperCase(),
        name: document.getElementById('stock-name').value,
        price: parseFloat(document.getElementById('stock-price').value),
        quantity: parseInt(document.getElementById('stock-quantity').value),
        expiryDate: document.getElementById('stock-expiry').value || null
    };
    
    try {
        const response = await apiRequest('/inventory/add-stock', {
            method: 'POST',
            body: JSON.stringify(stockData)
        });
        
        if (response.success) {
            showAlert('success', 'Stock added successfully');
            closeModal('add-stock-modal');
            loadInventoryData();
            loadOverviewData();
        }
    } catch (error) {
        showAlert('error', `Failed to add stock: ${error.message}`);
    }
}

function showMoveToShelfModal() {
    const modalHTML = `
        <div class="modal active" id="move-shelf-modal">
            <div class="modal-content">
                <div class="modal-header">
                    <h2>Move Items to Shelf</h2>
                    <button class="modal-close" onclick="closeModal('move-shelf-modal')">&times;</button>
                </div>
                <div class="modal-body">
                    <form id="move-shelf-form">
                        <div class="form-group">
                            <label for="move-item-code">Item Code*</label>
                            <input type="text" id="move-item-code" class="form-control" required>
                        </div>
                        <div class="form-group">
                            <label for="move-quantity">Quantity*</label>
                            <input type="number" id="move-quantity" class="form-control" required>
                        </div>
                    </form>
                </div>
                <div class="modal-footer">
                    <button class="btn btn-secondary" onclick="closeModal('move-shelf-modal')">Cancel</button>
                    <button class="btn btn-primary" onclick="submitMoveToShelf()">Move to Shelf</button>
                </div>
            </div>
        </div>
    `;
    
    document.getElementById('modal-container').innerHTML = modalHTML;
}

async function submitMoveToShelf() {
    const moveData = {
        itemCode: document.getElementById('move-item-code').value.toUpperCase(),
        quantity: parseInt(document.getElementById('move-quantity').value)
    };
    
    try {
        const response = await apiRequest('/inventory/move-to-shelf', {
            method: 'POST',
            body: JSON.stringify(moveData)
        });
        
        if (response.success) {
            showAlert('success', 'Items moved to shelf successfully');
            closeModal('move-shelf-modal');
            loadInventoryData();
        }
    } catch (error) {
        showAlert('error', `Failed to move items: ${error.message}`);
    }
}

// ===== Reports Section =====
async function generateDailySalesReport() {
    const date = document.getElementById('sales-report-date').value || new Date().toISOString().split('T')[0];
    
    try {
        const response = await apiRequest(`/reports/daily-sales?date=${date}&format=text`);
        
        if (response) {
            document.getElementById('report-output').style.display = 'block';
            document.getElementById('report-content').textContent = response;
        }
    } catch (error) {
        showAlert('error', `Failed to generate report: ${error.message}`);
    }
}

async function generateStockReport() {
    try {
        const response = await apiRequest('/reports/stock?format=text');
        
        if (response) {
            document.getElementById('report-output').style.display = 'block';
            document.getElementById('report-content').textContent = response;
        }
    } catch (error) {
        showAlert('error', `Failed to generate report: ${error.message}`);
    }
}

async function generateReorderReport() {
    try {
        const response = await apiRequest('/reports/reorder?format=text');
        
        if (response) {
            document.getElementById('report-output').style.display = 'block';
            document.getElementById('report-content').textContent = response;
        }
    } catch (error) {
        showAlert('error', `Failed to generate report: ${error.message}`);
    }
}

async function generateReshelveReport() {
    try {
        const response = await apiRequest('/reports/reshelve?format=text');
        
        if (response) {
            document.getElementById('report-output').style.display = 'block';
            document.getElementById('report-content').textContent = response;
        }
    } catch (error) {
        showAlert('error', `Failed to generate report: ${error.message}`);
    }
}

// ===== Users Section =====
function loadUsersData() {
    // Placeholder - to be implemented
    showAlert('info', 'User management feature coming soon');
}

function showRegisterUserModal() {
    showAlert('info', 'User registration feature coming soon');
}

// ===== Modal Functions =====
function closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.remove();
    }
}

// ===== Logout =====
async function handleLogout() {
    try {
        await apiRequest('/users/logout', { method: 'POST' });
    } catch (error) {
        console.error('Logout error:', error);
    } finally {
        sessionStorage.clear();
        window.location.href = '../../index.html';
    }
}

// ===== Helper Functions =====
async function viewItemDetails(itemCode) {
    try {
        const response = await apiRequest(`/inventory/items/${itemCode}`);
        
        if (response.success && response.data) {
            const item = response.data;
            showAlert('info', `Item: ${item.name} - Price: $${item.price} - Qty: ${item.quantity}`);
        }
    } catch (error) {
        showAlert('error', `Failed to load item details: ${error.message}`);
    }
}
