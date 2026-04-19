import java.util.ArrayList;
import java.util.Scanner;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Semaphore;

public class Main {

    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
        System.out.print("Введіть максимальну місткість сховища: ");
        int storageSize = Integer.parseInt(scanner.nextLine());

        System.out.print("Введіть загальну кількість продукції: ");
        int totalItems = Integer.parseInt(scanner.nextLine());

        System.out.print("Введіть кількість Виробників: ");
        int numProducers = Integer.parseInt(scanner.nextLine());

        System.out.print("Введіть кількість Споживачів: ");
        int numConsumers = Integer.parseInt(scanner.nextLine());

        Main main = new Main();
        main.starter(storageSize, totalItems, numProducers, numConsumers);
        scanner.close();
    }

    private void starter(int storageSize, int totalItems, int numProducers, int numConsumers) {
        Manager manager = new Manager(storageSize);

        int[] prodTasks = distributeTasks(totalItems, numProducers);
        int[] consTasks = distributeTasks(totalItems, numConsumers);

        for (int i = 0; i < numProducers; i++) {
            new Producer(prodTasks[i], manager, "Producer-" + (i + 1));
        }
        for (int i = 0; i < numConsumers; i++) {
            new Consumer(consTasks[i], manager, "Consumer-" + (i + 1));
        }
    }

    private int[] distributeTasks(int totalItems, int workersCount) {
        int[] tasks = new int[workersCount];
        int baseCount = totalItems / workersCount;
        int remainder = totalItems % workersCount;

        for (int i = 0; i < workersCount; i++) {
            tasks[i] = baseCount + (i < remainder ? 1 : 0);
        }
        return tasks;
    }
}

class Manager {
    public Semaphore access;
    public Semaphore full;
    public Semaphore empty;
    public CountDownLatch latch; 

    public ArrayList<String> storage = new ArrayList<>();
    public int globalItemCounter = 0;

    public Manager(int storageSize) {
        access = new Semaphore(1);
        full = new Semaphore(storageSize);
        empty = new Semaphore(0);
    }
}

class Producer implements Runnable {
    private final int itemsToProduce;
    private final Manager manager;
    private final String name;

    public Producer(int itemsToProduce, Manager manager, String name) {
        this.itemsToProduce = itemsToProduce;
        this.manager = manager;
        this.name = name;
        
        new Thread(this, name).start();
    }

    @Override
    public void run() {
        try {
            System.out.println("[INFO] " + name + " стартував. Має виробити: " + itemsToProduce);

            for (int i = 0; i < itemsToProduce; i++) {
                manager.full.acquire();   
                manager.access.acquire();

                manager.globalItemCounter++;
                String itemName = "item-" + manager.globalItemCounter;
                manager.storage.add(itemName);
                System.out.println("[+] " + name + " додав " + itemName + " \t| На складі: " + manager.storage.size());

                manager.access.release(); 
                manager.empty.release(); 

                Thread.sleep(50);
            }
        } catch (InterruptedException e) {
            e.printStackTrace();
        } 
    }
}

class Consumer implements Runnable {
    private final int itemsToConsume;
    private final Manager manager;
    private final String name;

    public Consumer(int itemsToConsume, Manager manager, String name) {
        this.itemsToConsume = itemsToConsume;
        this.manager = manager;
        this.name = name;
        
        new Thread(this, name).start();
    }

    @Override
    public void run() {
        try {
            System.out.println("[INFO] " + name + " стартував. Має спожити: " + itemsToConsume);

            for (int i = 0; i < itemsToConsume; i++) {
                manager.empty.acquire();  
                manager.access.acquire();

                String item = manager.storage.get(0);
                manager.storage.remove(0);
                System.out.println("[-] " + name + " взяв " + item + " \t| На складі: " + manager.storage.size());

                manager.access.release(); 
                manager.full.release();   

                Thread.sleep(200);
            }
        } catch (InterruptedException e) {
            e.printStackTrace();
        } 
    }
}
