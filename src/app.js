const config = {
  // Fake custom token shapes for local Betterleaks testing.
  internalServiceToken: "poc_prod_appsample0123456789abcdef01234567",
  signingSecret: "localPocAppSigningSecret0123456789abcdef",
};

console.log("POC app loaded", Object.keys(config));
