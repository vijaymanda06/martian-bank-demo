/**
 * Jest configuration for customer-auth service
 * Requirements: 1
 */
export default {
  testEnvironment: 'node',
  testMatch: ['**/__tests__/**/*.test.js'],
  verbose: true,
  testTimeout: 10000,
  transform: {},
  moduleFileExtensions: ['js', 'mjs'],
  collectCoverageFrom: [
    '**/*.js',
    '!**/node_modules/**',
    '!**/coverage/**',
    '!jest.config.js'
  ]
};
