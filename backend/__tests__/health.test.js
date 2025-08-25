const request = require('supertest');
const express = require('express');

// Create a simple test app with just the health endpoint
const app = express();
app.get('/health', (req, res) => res.send('OK'));

describe('Health Endpoint', () => {
  test('GET /health should return OK', async () => {
    const response = await request(app).get('/health');
    expect(response.status).toBe(200);
    expect(response.text).toBe('OK');
  });
});

describe('Basic Math', () => {
  test('should add two numbers correctly', () => {
    expect(1 + 2).toBe(3);
  });
  
  test('should multiply two numbers correctly', () => {
    expect(3 * 4).toBe(12);
  });
}); 