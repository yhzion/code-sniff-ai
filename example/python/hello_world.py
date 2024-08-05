class HelloWorld:
    def __init__(self):
        self.message = 'Hello, World!'

    def say_hello(self):
        print(self.message)

if __name__ == "__main__":
    hello = HelloWorld()
    hello.say_hello()