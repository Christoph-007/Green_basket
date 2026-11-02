/**
 * Unit price of a product with an optional preparation (e.g. "chopped").
 * The single source of truth for the cart and orders, so what the cart shows
 * is what the order charges.
 *
 * `preparation` may be the option's type ("chopped") or its _id.
 * @returns {{ unitPrice: number, preparation: string }}
 */
function unitPrice(product, preparation) {
    let price = Number(product.price) || 0;
    let prepName = 'whole';
    if (preparation && preparation !== 'whole' && Array.isArray(product.preparationOptions)) {
        const option = product.preparationOptions.find(o =>
            (o._id && o._id.toString() === String(preparation)) || o.type === preparation);
        if (option) {
            price += Number(option.additionalPrice) || 0;
            prepName = option.type;
        }
    }
    return { unitPrice: Math.round(price * 100) / 100, preparation: prepName };
}

const round2 = (n) => Math.round(n * 100) / 100;

module.exports = { unitPrice, round2 };
