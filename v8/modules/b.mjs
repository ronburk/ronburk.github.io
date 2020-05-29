/* module b */
import {a} from "a.mjs";
let y = a();
let z = "oh-oh";
export function b() { return z + "b"; }
console.log(y);
