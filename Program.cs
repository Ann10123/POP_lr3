using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;

namespace ProducerConsumer
{
    class Program
    {
        static void Main(string[] args)
        {   
            Console.Write("Введіть максимальну місткість сховища: ");
            int storageSize = int.Parse(Console.ReadLine());

            Console.Write("Введіть загальну кількість продукції: ");
            int totalItems = int.Parse(Console.ReadLine());

            Console.Write("Введіть кількість Виробників: ");
            int numProducers = int.Parse(Console.ReadLine());

            Console.Write("Введіть кількість Споживачів: ");
            int numConsumers = int.Parse(Console.ReadLine());
            Console.WriteLine();

            Program program = new Program();
            program.Starter(storageSize, totalItems, numProducers, numConsumers);
        }

        private Semaphore Access;
        private Semaphore Full;
        private Semaphore Empty;
        
        private readonly List<string> storage = new List<string>();
        private int globalItemCounter = 0; 

        private void Starter(int storageSize, int totalItems, int numProducers, int numConsumers)
        {
            Access = new Semaphore(1, 1);
            Full = new Semaphore(storageSize, storageSize);
            Empty = new Semaphore(0, storageSize);

            int[] prodTasks = DistributeTasks(totalItems, numProducers);
            int[] consTasks = DistributeTasks(totalItems, numConsumers);

            for (int i = 0; i < numProducers; i++)
            {
                Thread pThread = new Thread(Producer);
                pThread.Name = $"Producer-{i + 1}";
                pThread.Start(prodTasks[i]); 
            }

            for (int i = 0; i < numConsumers; i++)
            {
                Thread cThread = new Thread(Consumer);
                cThread.Name = $"Consumer-{i + 1}";
                cThread.Start(consTasks[i]); 
            }
        }

        private int[] DistributeTasks(int totalItems, int workersCount)
        {
            int[] tasks = new int[workersCount];
            int baseCount = totalItems / workersCount;
            int remainder = totalItems % workersCount;

            for (int i = 0; i < workersCount; i++)
            {
                tasks[i] = baseCount + (i < remainder ? 1 : 0);
            }
            return tasks;
        }

        private void Producer(object itemsToProduceObj)
        {
            int itemsToProduce = (int)itemsToProduceObj;
            string name = Thread.CurrentThread.Name;
                
            Console.WriteLine($"[INFO] {name} стартував. Має виробити: {itemsToProduce}");

            for (int i = 0; i < itemsToProduce; i++)
            {
                Full.WaitOne();
                Access.WaitOne();

                globalItemCounter++;
                string itemName = $"item-{globalItemCounter}";
                storage.Add(itemName);
                Console.WriteLine($"[+] {name} додав {itemName} \t| На складі: {storage.Count}");

                Access.Release();
                Empty.Release();

                Thread.Sleep(50); 
            }
        }

        private void Consumer(object itemsToConsumeObj)
        {
            int itemsToConsume = (int)itemsToConsumeObj;
            string name = Thread.CurrentThread.Name;
                
            Console.WriteLine($"[INFO] {name} стартував. Має спожити: {itemsToConsume}");

            for (int i = 0; i < itemsToConsume; i++)
            {
                Empty.WaitOne();
                Access.WaitOne();

                string item = storage.ElementAt(0);
                storage.RemoveAt(0);
                Console.WriteLine($"[-] {name} взяв {item} \t| На складі: {storage.Count}");

                Access.Release();
                Full.Release();

                Thread.Sleep(200); 
            }
        }
    }
}
