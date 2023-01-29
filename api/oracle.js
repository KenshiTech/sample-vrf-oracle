import { decode, prove, getFastVerifyComponents } from "@kenshi.io/node-ecvrf";
import { createHash } from "crypto";
import Elliptic from "elliptic";

const EC = new Elliptic.ec("secp256k1");

const getPublicKey = (privateKey) => {
  const key = EC.keyFromPrivate(privateKey);
  return {
    key: key.getPublic("hex"),
    compressed: key.getPublic(true, "hex"),
    x: key.getPublic().getX(),
    y: key.getPublic().getY(),
  };
};

const fromHex = (hex) => Buffer.from(hex.slice(2));

const hash = (...args) => {
  const sha256 = createHash("sha256");
  for (const arg of args) {
    sha256.update(arg);
  }
  return sha256.digest().toString("hex");
};

const generateRandomness = (entry) => {
  const publicKey = getPublicKey(process.env.VRF_PRIVATE_KEY);

  const alpha = hash(
    fromHex(entry.transaction.hash),
    fromHex(entry.log.index),
    fromHex(entry.block.address),
    fromHex(entry.event.args.requestId)
  );

  const proof = prove(process.env.VRF_PRIVATE_KEY, alpha);
  const fast = getFastVerifyComponents(publicKey.key, proof, alpha);
  const [Gamma, c, s] = decode(proof);

  return { alpha, proof, fast, Gamma, c, s };
};

export default function handler(request, response) {
  const { entry } = request.body;
  const { alpha, fast, Gamma, c, s } = generateRandomness(entry);
  response.status(200).json({
    method: "setRandomness",
    args: [
      [Gamma.x.toString(), Gamma.y.toString(), c.toString(), s.toString()],
      `0x${alpha}`,
      [fast.uX, fast.uY],
      [fast.sHX, fast.sHY, fast.cGX, fast.cGY],
      entry.event.args.requestId,
    ],
    maxGas: "10000000000000000", // 0.01 ETH
    abort: false,
  });
}
