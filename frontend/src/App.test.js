import { render, screen } from '@testing-library/react';
import App from './App';

test('renders todo app', () => {
  render(<App />);
  const linkElement = screen.getByText(/todo/i);
  expect(linkElement).toBeInTheDocument();
});

test('basic math operations', () => {
  expect(2 + 2).toBe(4);
  expect(5 * 3).toBe(15);
}); 