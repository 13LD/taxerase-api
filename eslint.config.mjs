import js from "@eslint/js";
import globals from "globals";
import reactHooks from "eslint-plugin-react-hooks";

export default [
  {
    ignores: ["app/assets/builds/**", "node_modules/**", "tmp/**", "vendor/**"]
  },
  js.configs.recommended,
  {
    files: ["app/javascript/**/*.{js,jsx}"],
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "module",
      parserOptions: {
        ecmaFeatures: {
          jsx: true
        }
      },
      globals: {
        ...globals.browser,
        ...globals.node
      }
    }
  },
  reactHooks.configs.flat.recommended,
  {
    files: ["app/javascript/**/*.{js,jsx}"],
    rules: {
      "no-unused-vars": [
        "error",
        {
          argsIgnorePattern: "^_",
          caughtErrorsIgnorePattern: "^_",
          varsIgnorePattern: "^React$"
        }
      ],
      "react-hooks/set-state-in-effect": "off"
    }
  }
];
