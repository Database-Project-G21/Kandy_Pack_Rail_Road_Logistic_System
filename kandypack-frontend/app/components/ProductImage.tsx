"use client";
import Image from "next/image";
import { useState } from "react";
function category(name: string) {
  const n = name.toLowerCase();
  if (n.includes("soap")) return "soap";
  if (n.includes("margarine")) return "margarine";
  if (n.includes("cracker")) return "crackers";
  if (n.includes("milk powder")) return "milk";
  if (n.includes("cream soda")) return "soda";
  if (n.includes("biscuit")) return "biscuits";
  if (n.includes("detergent")) return "detergent";
  if (n.includes("cola")) return "cola";
  if (n.includes("noodle")) return "noodles";
  if (n.includes("dishwash")) return "dishwash";
  if (n.includes("toothpaste")) return "toothpaste";
  if (n.includes("malt")) return "malt";
  return null;
}
export default function ProductImage({productName}: {productName: string}) {
  const [failed, setFailed] = useState(false);
  const kind = category(productName);
  return <div className="product-art">{kind && !failed ? <Image src={`/products/${kind}.png`} alt={`Illustrative image for ${productName}; packaging may differ`} fill sizes="(max-width: 640px) 50vw, (max-width: 900px) 33vw, 25vw" unoptimized onError={() => setFailed(true)} /> : <span className="image-fallback">KandyPack<br /><small>Product image coming soon</small></span>}<span className="sample-label">Sample image</span></div>;
}
