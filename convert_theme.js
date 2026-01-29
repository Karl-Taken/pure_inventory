const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, 'web/src/styles/qb-theme.scss');
const content = fs.readFileSync(filePath, 'utf8');

const newContent = content.replace(/(\d*\.?\d+)px/g, (match, p1) => {
    const px = parseFloat(p1);
    const rem = px / 16;
    // Limit decimals to 4 to avoid 0.3333333333
    return `${parseFloat(rem.toFixed(5))}rem`;
});

fs.writeFileSync(filePath, newContent);
console.log('Converted qb-theme.scss to rem');
