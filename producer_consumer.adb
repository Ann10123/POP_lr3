with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with GNAT.Semaphores; use GNAT.Semaphores;
with Ada.Containers.Indefinite_Doubly_Linked_Lists; use Ada.Containers;

procedure Producer_Consumer is
   package String_Lists is new Indefinite_Doubly_Linked_Lists (String);
   use String_Lists;

   Storage_Size, Total_Items, Num_Producers, Num_Consumers : Integer;

   procedure Starter (Storage_Capacity, Items_Count, Producers_Count, Consumers_Count : Integer) is
      Storage : List;
      Global_Item_Counter : Integer := 0;

      -- Семафори
      Access_Storage : Counting_Semaphore (1, Default_Ceiling);
      Full_Storage   : Counting_Semaphore (Storage_Capacity, Default_Ceiling);
      Empty_Storage  : Counting_Semaphore (0, Default_Ceiling);

      task type Producer_Task is
         entry Start (ID : Integer; Items_To_Produce : Integer);
      end Producer_Task;

      task type Consumer_Task is
         entry Start (ID : Integer; Items_To_Consume : Integer);
      end Consumer_Task;

      task body Producer_Task is
         My_ID : Integer;
         Items : Integer;
      begin
         accept Start (ID : Integer; Items_To_Produce : Integer) do
            My_ID := ID;
            Items := Items_To_Produce;
         end Start;

         Put_Line ("[INFO] Producer-" & Integer'Image(My_ID) & " started. Must produce:" & Integer'Image(Items));

         for I in 1 .. Items loop
            Full_Storage.Seize;
            Access_Storage.Seize;

            Global_Item_Counter := Global_Item_Counter + 1;
            declare
               Item_Name : String := "item-" & Integer'Image(Global_Item_Counter);
            begin
               Storage.Append (Item_Name);
               Put_Line ("[+] Producer-" & Integer'Image(My_ID) & " added " & Item_Name & " | In stock:" & Count_Type'Image(Storage.Length));
            end;

            Access_Storage.Release;
            Empty_Storage.Release;

            delay 0.050; 
         end loop;
      end Producer_Task;

      task body Consumer_Task is
         My_ID : Integer;
         Items : Integer;
      begin
         accept Start (ID : Integer; Items_To_Consume : Integer) do
            My_ID := ID;
            Items := Items_To_Consume;
         end Start;

         Put_Line ("[INFO] Consumer-" & Integer'Image(My_ID) & " started. Must consume:" & Integer'Image(Items));

         for I in 1 .. Items loop
            Empty_Storage.Seize;
            Access_Storage.Seize;

            declare
               Item_Name : String := First_Element (Storage);
            begin
               Put_Line ("[-] Consumer-" & Integer'Image(My_ID) & " took " & Item_Name & " | In stock: " & Count_Type'Image(Storage.Length - 1));
            end;

            Storage.Delete_First;

            Access_Storage.Release;
            Full_Storage.Release;

            delay 0.200; 
         end loop;
      end Consumer_Task;

      type Producer_Array is array (1 .. Producers_Count) of Producer_Task;
      type Consumer_Array is array (1 .. Consumers_Count) of Consumer_Task;

      Producers : Producer_Array;
      Consumers : Consumer_Array;

      Base_Prod : Integer := Items_Count / Producers_Count;
      Rem_Prod  : Integer := Items_Count mod Producers_Count;
      Base_Cons : Integer := Items_Count / Consumers_Count;
      Rem_Cons  : Integer := Items_Count mod Consumers_Count;
      Tasks_To_Do : Integer;

   begin
      for I in 1 .. Producers_Count loop
         Tasks_To_Do := Base_Prod;
         if I <= Rem_Prod then
            Tasks_To_Do := Tasks_To_Do + 1;
         end if;
         Producers(I).Start (I, Tasks_To_Do);
      end loop;

      for I in 1 .. Consumers_Count loop
         Tasks_To_Do := Base_Cons;
         if I <= Rem_Cons then
            Tasks_To_Do := Tasks_To_Do + 1;
         end if;
         Consumers(I).Start (I, Tasks_To_Do);
      end loop;

   end Starter;

begin
   Put ("Enter the maximum storage capacity: ");
   Get (Storage_Size);

   Put ("Enter the total quantity of products: ");
   Get (Total_Items);

   Put ("Enter the number of Producers: ");
   Get (Num_Producers);

   Put ("Enter the number of Consumers: ");
   Get (Num_Consumers);
   New_Line;

   Starter (Storage_Size, Total_Items, Num_Producers, Num_Consumers);
end Producer_Consumer;
