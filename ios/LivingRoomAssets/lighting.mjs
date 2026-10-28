// Indoor only. Window/weather rendering uses a separate canvas and is unaffected.
export function roomLighting(daylight, weatherDim, lampOn) {
  const day = Math.min(1, Math.max(0, Number(daylight) || 0));
  const dim = Math.min(1, Math.max(0, Number(weatherDim) || 0));
  const ambient = .59 + day * .41 * (1 - dim * .55);
  const contribution = lampOn ? .20 * (1 - day * .50) : 0;
  return {brightness: Math.min(1.02, ambient + contribution), lampGlow: lampOn ? .31 - day * .12 : 0};
}
