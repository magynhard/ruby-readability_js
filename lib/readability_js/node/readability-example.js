const { Readability, isProbablyReaderable } = require('@mozilla/readability');
const { JSDOM } = require('jsdom');

const doc = new JSDOM("<body>Look at this cat: <img src='./cat.jpg'></body>", {
    url: "https://www.example.com/the-page-i-got-the-source-from"
});
let reader = new Readability(doc.window.document);
let article = reader.parse();

console.log(article);

if(isProbablyReaderable(doc.window.document)) {
    console.log("This document is probably readerable.");
} else {
    console.log("This document is probably not readerable.");
}