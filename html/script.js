// ============================================================================
// DB-NAZAR - NUI Script
// ============================================================================

let shopData = null;
let currentCategory = null;

// ============================================================================
// MESSAGE HANDLER
// ============================================================================

window.addEventListener('message', function(event) {
    const data = event.data;

    switch (data.action) {
        case 'openShop':
            openShop(data.data);
            break;
        case 'closeShop':
            closeShop();
            break;
        case 'showFortune':
            showFortune(data.data);
            break;
    }
});

// ============================================================================
// KEY HANDLER
// ============================================================================

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape' || event.key === 'Backspace') {
        closeAndNotify();
    }
});

// ============================================================================
// RESOURCE NAME HELPER
// ============================================================================

function getResource() {
    if (window.GetParentResourceName) {
        return window.GetParentResourceName();
    }
    return 'DB-Nazar';
}

// ============================================================================
// POST HELPER
// ============================================================================

function postNUI(endpoint, data) {
    return fetch('https://' + getResource() + '/' + endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data || {})
    }).catch(function(err) {
        console.error('NUI POST error:', err);
    });
}

// ============================================================================
// CURRENCY FORMAT
// ============================================================================

function formatCurrency(amount) {
    const symbol = (shopData && shopData.nuiSettings && shopData.nuiSettings.currencySymbol) || '$';
    return symbol + parseFloat(amount).toFixed(2);
}

// ============================================================================
// OPEN / CLOSE
// ============================================================================

function openShop(data) {
    shopData = data;
    const container = document.getElementById('nazar-container');
    container.classList.remove('hidden');

    // Set header info
    if (data.nuiSettings) {
        document.getElementById('shop-title').textContent = data.nuiSettings.title || 'Madam Nazar';
        document.getElementById('shop-subtitle').textContent = data.nuiSettings.subtitle || '';
    }

    // Set greeting
    if (data.greeting) {
        document.getElementById('greeting-text').textContent = '"' + data.greeting + '"';
    }

    // Setup all tabs
    setupCollectorBagBanner(data);
    setupCategories(data.categories);
    setupSellTab(data);
    setupCollectionsTab(data);
    setupFortuneTab(data);

    // Default to buy tab
    switchTab('buy');

    // Select first category
    if (data.categories && data.categories.length > 0) {
        selectCategory(data.categories[0].id);
    }
}

function closeShop() {
    const container = document.getElementById('nazar-container');
    container.classList.add('hidden');
    shopData = null;
    removeConfirmTooltip();
}

function closeAndNotify() {
    if (!shopData) return;
    postNUI('closeUI');
    closeShop();
}

// ============================================================================
// TAB NAVIGATION
// ============================================================================

document.querySelectorAll('.tab-btn').forEach(function(btn) {
    btn.addEventListener('click', function() {
        switchTab(this.dataset.tab);
    });
});

function switchTab(tabId) {
    // Update buttons
    document.querySelectorAll('.tab-btn').forEach(function(btn) {
        btn.classList.toggle('active', btn.dataset.tab === tabId);
    });

    // Update content
    document.querySelectorAll('.tab-content').forEach(function(content) {
        content.classList.remove('active');
    });

    var targetContent = document.getElementById('tab-' + tabId);
    if (targetContent) {
        targetContent.classList.add('active');
    }
}

// ============================================================================
// COLLECTOR BAG BANNER
// ============================================================================

function setupCollectorBagBanner(data) {
    var banner = document.getElementById('collector-bag-banner');

    if (!data.hasCollectorBag && data.collectorBag) {
        banner.classList.remove('hidden');
        document.getElementById('bag-description').textContent = data.collectorBag.description;
        document.getElementById('bag-price').textContent = formatCurrency(data.collectorBag.price);

        document.getElementById('buy-bag-btn').onclick = function() {
            showConfirm(
                'Purchase ' + data.collectorBag.label + ' for ' + formatCurrency(data.collectorBag.price) + '?',
                function() {
                    postNUI('purchaseCollectorBag');
                }
            );
        };
    } else {
        banner.classList.add('hidden');
    }
}

// ============================================================================
// CATEGORIES (BUY TAB)
// ============================================================================

function setupCategories(categories) {
    var nav = document.getElementById('category-nav');
    nav.innerHTML = '';

    if (!categories) return;

    categories.forEach(function(cat) {
        var btn = document.createElement('button');
        btn.className = 'category-btn';
        btn.dataset.category = cat.id;
        btn.innerHTML = '<span>' + (cat.icon || '') + '</span> ' + cat.label;
        btn.addEventListener('click', function() {
            selectCategory(cat.id);
        });
        nav.appendChild(btn);
    });
}

function selectCategory(categoryId) {
    currentCategory = categoryId;

    // Update button states
    document.querySelectorAll('.category-btn').forEach(function(btn) {
        btn.classList.toggle('active', btn.dataset.category === categoryId);
    });

    // Find category
    var category = null;
    for (var i = 0; i < shopData.categories.length; i++) {
        if (shopData.categories[i].id === categoryId) {
            category = shopData.categories[i];
            break;
        }
    }
    if (!category) return;

    // Render items
    renderBuyItems(category.items);
}

function renderBuyItems(items) {
    var grid = document.getElementById('buy-items-grid');
    grid.innerHTML = '';

    if (!items || items.length === 0) {
        grid.innerHTML = '<div class="empty-state"><span class="empty-icon">📦</span><p>No items in this category.</p></div>';
        return;
    }

    items.forEach(function(item) {
        var hasRequirement = !item.requiredItem || shopData.hasCollectorBag;
        var card = document.createElement('div');
        card.className = 'item-card' + (hasRequirement ? '' : ' locked');

        var requirementHTML = '';
        if (item.requiredItem) {
            if (hasRequirement) {
                requirementHTML = '<div class="item-requirement met">✓ Collector\'s Bag owned</div>';
            } else {
                requirementHTML = '<div class="item-requirement">🔒 Requires Collector\'s Bag</div>';
            }
        }

        var buttonHTML = '';
        if (hasRequirement) {
            buttonHTML = '<button class="item-action-btn" data-item="' + item.item + '" data-price="' + item.price + '" data-label="' + item.label + '" data-required="' + (item.requiredItem || '') + '">Purchase</button>';
        }

        card.innerHTML =
            '<div class="item-name">' + item.label + '</div>' +
            '<div class="item-description">' + (item.description || '') + '</div>' +
            '<div class="item-price">' + formatCurrency(item.price) + '</div>' +
            requirementHTML +
            buttonHTML;

        if (hasRequirement) {
            var buyBtn = card.querySelector('.item-action-btn');
            (function(currentItem) {
                buyBtn.addEventListener('click', function(e) {
                    e.stopPropagation();
                    showConfirm(
                        'Purchase ' + currentItem.label + ' for ' + formatCurrency(currentItem.price) + '?',
                        function() {
                            postNUI('purchaseItem', {
                                item: currentItem.item,
                                price: currentItem.price,
                                requiredItem: currentItem.requiredItem || null
                            });
                        }
                    );
                });
            })(item);
        }

        grid.appendChild(card);
    });
}

// ============================================================================
// SELL TAB
// ============================================================================

function setupSellTab(data) {
    var grid = document.getElementById('sell-items-grid');
    var emptyState = document.getElementById('sell-empty');
    grid.innerHTML = '';

    var hasSellableItems = false;

    // Individual collectibles
    if (data.collectibles && data.collectibles.individual) {
        data.collectibles.individual.forEach(function(item) {
            var count = (data.playerCollectibles && data.playerCollectibles[item.item]) || 0;
            if (count > 0) {
                hasSellableItems = true;
                var card = createSellCard(item, count);
                grid.appendChild(card);
            }
        });
    }

    // Collection items (individual sale)
    if (data.collectibles && data.collectibles.collections) {
        data.collectibles.collections.forEach(function(collection) {
            collection.items.forEach(function(item) {
                var count = (data.playerCollectibles && data.playerCollectibles[item.item]) || 0;
                if (count > 0) {
                    hasSellableItems = true;
                    var card = createSellCard(item, count);
                    grid.appendChild(card);
                }
            });
        });
    }

    if (hasSellableItems) {
        emptyState.classList.add('hidden');
    } else {
        emptyState.classList.remove('hidden');
    }
}

function createSellCard(item, count) {
    var card = document.createElement('div');
    card.className = 'item-card';

    card.innerHTML =
        '<div class="item-name">' + item.label + '</div>' +
        '<div class="item-description">Quantity: ' + count + '</div>' +
        '<div class="item-price sell-price">+' + formatCurrency(item.sellPrice) + '</div>' +
        '<button class="item-action-btn sell-btn">Sell to Nazar</button>';

    var sellBtn = card.querySelector('.sell-btn');
    (function(currentItem) {
        sellBtn.addEventListener('click', function(e) {
            e.stopPropagation();
            showConfirm(
                'Sell ' + currentItem.label + ' for ' + formatCurrency(currentItem.sellPrice) + '?',
                function() {
                    postNUI('sellItem', {
                        item: currentItem.item,
                        sellPrice: currentItem.sellPrice
                    });
                }
            );
        });
    })(item);

    return card;
}

// ============================================================================
// COLLECTIONS TAB
// ============================================================================

function setupCollectionsTab(data) {
    var list = document.getElementById('collections-list');
    list.innerHTML = '';

    if (!data.collectibles || !data.collectibles.collections) return;

    data.collectibles.collections.forEach(function(collection) {
        var card = document.createElement('div');
        card.className = 'collection-card';

        var ownedCount = 0;
        var totalItems = collection.items.length;
        var baseTotal = 0;
        var itemsHTML = '';

        collection.items.forEach(function(item) {
            var hasItem = (data.playerCollectibles && data.playerCollectibles[item.item]) ? true : false;
            if (hasItem) {
                ownedCount++;
            }
            baseTotal += item.sellPrice;

            itemsHTML +=
                '<div class="collection-item">' +
                    '<span class="item-label">' + item.label + '</span>' +
                    '<span>' +
                        '<span class="item-sell-price">' + formatCurrency(item.sellPrice) + '</span>' +
                        '<span class="item-status ' + (hasItem ? 'has-item' : 'missing-item') + '">' + (hasItem ? '✓' : '✗') + '</span>' +
                    '</span>' +
                '</div>';
        });

        var bonusTotal = baseTotal * (collection.setBonus || 1.0);
        var bonusPercent = Math.round(((collection.setBonus || 1.0) - 1.0) * 100);
        var isComplete = ownedCount === totalItems;

        card.innerHTML =
            '<div class="collection-header">' +
                '<div class="collection-title">' +
                    '<span class="collection-icon">' + (collection.icon || '📦') + '</span>' +
                    '<h4>' + collection.label + '</h4>' +
                '</div>' +
                '<span class="collection-bonus">+' + bonusPercent + '% Set Bonus</span>' +
            '</div>' +
            '<div class="collection-items">' + itemsHTML + '</div>' +
            '<div class="collection-footer">' +
                '<div>' +
                    '<div class="collection-progress">' +
                        'Progress: <span class="progress-count">' + ownedCount + '/' + totalItems + '</span>' +
                    '</div>' +
                    '<div class="collection-total">' +
                        'Set Value: <span class="bonus-amount">' + formatCurrency(bonusTotal) + '</span>' +
                        ' <span style="font-size: 11px; color: #7a6a4f;">(base: ' + formatCurrency(baseTotal) + ')</span>' +
                    '</div>' +
                '</div>' +
                '<button class="sell-collection-btn" ' + (!isComplete ? 'disabled' : '') + '>' +
                    (isComplete ? 'Sell Complete Set' : 'Incomplete Set') +
                '</button>' +
            '</div>';

        if (isComplete) {
            var sellBtn = card.querySelector('.sell-collection-btn');
            (function(currentCollection, currentBonusTotal) {
                sellBtn.addEventListener('click', function() {
                    showConfirm(
                        'Sell complete ' + currentCollection.label + ' for ' + formatCurrency(currentBonusTotal) + '?',
                        function() {
                            var itemNames = [];
                            currentCollection.items.forEach(function(i) {
                                itemNames.push(i.item);
                            });
                            postNUI('sellCollection', {
                                collectionId: currentCollection.id,
                                items: itemNames,
                                totalPrice: currentBonusTotal
                            });
                        }
                    );
                });
            })(collection, bonusTotal);
        }

        list.appendChild(card);
    });
}

// ============================================================================
// FORTUNE TAB
// ============================================================================

function setupFortuneTab(data) {
    if (data.fortuneTelling) {
        document.querySelector('#fortune-cost span').textContent = formatCurrency(data.fortuneTelling.cost);
    }

    document.getElementById('fortune-btn').onclick = function() {
        postNUI('requestFortune');
    };
}

function showFortune(data) {
    var display = document.getElementById('fortune-display');
    var text = document.getElementById('fortune-text');

    text.textContent = '"' + data.text + '"';
    display.classList.remove('hidden');
}

// ============================================================================
// CLOSE BUTTON
// ============================================================================

document.getElementById('close-btn').addEventListener('click', closeAndNotify);

// ============================================================================
// FORTUNE DISMISS
// ============================================================================

document.getElementById('fortune-dismiss').addEventListener('click', function() {
    document.getElementById('fortune-display').classList.add('hidden');
});

// ============================================================================
// CONFIRMATION DIALOG
// ============================================================================

function showConfirm(message, onConfirm) {
    removeConfirmTooltip();

    var tooltip = document.createElement('div');
    tooltip.className = 'confirm-tooltip';
    tooltip.id = 'confirm-tooltip';
    tooltip.innerHTML =
        '<p>' + message + '</p>' +
        '<div class="confirm-buttons">' +
            '<button class="confirm-yes">Confirm</button>' +
            '<button class="confirm-no">Cancel</button>' +
        '</div>';

    tooltip.style.top = '50%';
    tooltip.style.left = '50%';
    tooltip.style.transform = 'translate(-50%, -50%)';

    document.body.appendChild(tooltip);

    tooltip.querySelector('.confirm-yes').addEventListener('click', function() {
        removeConfirmTooltip();
        if (onConfirm) onConfirm();
    });

    tooltip.querySelector('.confirm-no').addEventListener('click', function() {
        removeConfirmTooltip();
    });
}

function removeConfirmTooltip() {
    var existing = document.getElementById('confirm-tooltip');
    if (existing) {
        existing.remove();
    }
}
