import { keygen } from "@kenshi.io/node-ecvrf";

const keypair = keygen();

console.log(`Private key: ${keypair.secret_key}`);
console.log(`Public key: ${keypair.public_key.compressed}`);
