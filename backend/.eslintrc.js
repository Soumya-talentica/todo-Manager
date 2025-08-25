module.exports = {
  env: {
    node: true,
    es2021: true,
    jest: true,
  },
  extends: ['eslint:recommended'],
  parserOptions: {
    ecmaVersion: 12,
    sourceType: 'module',
  },
  rules: {
    'no-unused-vars': 'warn',
    'no-console': 'off',
    'no-process-exit': 'off',
    'prefer-const': 'error',
    'no-var': 'error',
  },
  globals: {
    process: 'readonly',
  },
}; 