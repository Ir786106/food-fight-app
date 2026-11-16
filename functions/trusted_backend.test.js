const assert = require("node:assert/strict");
const { test } = require("node:test");
const { createServer } = require("./trusted_backend");

test("verified accounts have independent request limits, reset each minute", async (t) => {
  let time = 0;
  let calls = 0;
  const server = createServer({
    requestLimit: 1,
    now: () => time,
    verifyToken: async (token) => ({ uid: token }),
    handlers: { quoteOrder: async () => ++calls },
  });
  await new Promise((resolve, reject) =>
    server.once("error", reject).listen(0, "127.0.0.1", resolve));
  t.after(() => new Promise((resolve) => server.close(resolve)));
  const base = `http://127.0.0.1:${server.address().port}`;
  const quote = (token) => fetch(base + "/v1/quoteOrder", {
    method: "POST",
    headers: { authorization: "Bearer " + token, "content-type": "application/json" },
    body: JSON.stringify({ data: {} }),
  });

  assert.equal((await quote("first")).status, 200);
  const limited = await quote("first");
  assert.equal(limited.status, 429);
  assert.equal(limited.headers.get("retry-after"), "60");
  assert.equal((await limited.json()).error.code, "resource-exhausted");
  assert.equal((await quote("second")).status, 200);
  assert.equal((await fetch(base + "/health")).status, 200);
  time = 60000;
  assert.equal((await quote("first")).status, 200);
  assert.equal(calls, 3);
});
