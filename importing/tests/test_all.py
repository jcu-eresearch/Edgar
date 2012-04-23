import unittest
import logging
import test_mockala
import test_sync

if __name__ == '__main__':
    logging.basicConfig();
    tests = [
        unittest.TestLoader().loadTestsFromTestCase(test_mockala.TestMockALA),
        unittest.TestLoader().loadTestsFromTestCase(test_sync.TestSync)
    ]
    alltests = unittest.TestSuite(tests)
    unittest.TextTestRunner(verbosity=3).run(alltests)
