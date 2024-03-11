import { addToCallback, CircuitValue, getReceipt } from "@axiom-crypto/client";

// For type safety, define the input types to your circuit here.
// These should be the _variable_ inputs to your circuit. Constants can be hard-coded into the circuit itself.
export interface CircuitInputs {
	blockNumber: CircuitValue;
	txIdx: CircuitValue;
	logIdx: CircuitValue;
}

// Default inputs to use for compiling the circuit. These values should be different than the inputs fed into
// the circuit at proving time.
export const defaultInputs = {
	blockNumber: 19400004, // note: ensure this block contains the eventSchema we are looking for
	txIdx: 0,
	logIdx: 9,
};

// The function name `circuit` is searched for by default by our Axiom CLI; if you decide to
// change the function name, you'll also need to ensure that you also pass the Axiom CLI flag
// `-f <circuitFunctionName>` for it to work
export const circuit = async (inputs: CircuitInputs) => {
	const eventSchema =
		"0x05a5d0ee0cd31fa17105f3377bc6e4a373e033600b3cf02ce30bffb01cd71b83";
	const receipt = getReceipt(inputs.blockNumber, inputs.txIdx);
	const receiptLog = receipt.log(inputs.logIdx);

	const retrievedEventSchema = await receiptLog.topic(0, eventSchema);
	const user = await receiptLog.topic(1, eventSchema);
	const asset = await receiptLog.topic(2, eventSchema);

	const unscaledAmount = await receiptLog.data(0, eventSchema);
	const scaledAmount = await receiptLog.data(1, eventSchema);

	// get the `address` field of the receipt log
	const receiptAddr = await receiptLog.address();

	// We call `addToCallback` on all values that we would like to be passed to our contract after the circuit has
	// been proven in ZK. The values can then be handled by our contract once the prover calls the callback function.
	addToCallback(inputs.blockNumber);
	addToCallback(user);
	addToCallback(asset);
	addToCallback(unscaledAmount);
	addToCallback(scaledAmount);

	addToCallback(receiptAddr);
};
