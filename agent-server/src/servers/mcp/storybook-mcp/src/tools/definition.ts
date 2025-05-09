import type { ToolCallback } from "@modelcontextprotocol/sdk/server/mcp.js";
import { type ZodRawShape, z } from "zod";
import { zodToJsonSchema } from "zod-to-json-schema";
import { getComponentUsage } from "./get-component-usage";
import { listComponents } from "./list-components";
import { listStorybooks } from "./list-storybooks";

type ToolDefinition = {
  name: string;
  description: string;
  paramsSchema: ZodRawShape;
  callback: ToolCallback<ZodRawShape>;
};

const storybookKeySchema = z
  .string()
  .describe("The identifier used to select the target Storybook instance.");

export const TOOLS_DEFINITIONS: ToolDefinition[] = [
  {
    name: "list-storybook",
    description: "Lists all available Storybook instances that can be queried.",
    paramsSchema: {},
    callback: async () => await listStorybooks(),
  },
  {
    name: "list-components",
    description: "Lists all components registered within a specified Storybook instance.",
    paramsSchema: { storybookKey: storybookKeySchema },
    callback: async ({ storybookKey }) => await listComponents({ storybookKey }),
  },
  {
    name: "get-component-usage",
    description:
      "Retrieves usage examples and documentation for a specific component in a given Storybook instance.",
    paramsSchema: {
      storybookKey: storybookKeySchema,
      componentId: z
        .string()
        .describe("The unique story ID of the component whose usage details are to be retrieved."),
      variantId: z
        .string()
        .optional()
        .describe(
          "The unique ID of the variant whose usage details are to be retrieved. If not provided, all variants will be retrieved."
        ),
    },
    callback: async ({ storybookKey, componentId, variantId }) =>
      await getComponentUsage({ storybookKey, componentId, variantId }),
  },
];
